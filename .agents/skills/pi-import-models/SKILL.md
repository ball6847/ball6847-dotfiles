---
name: pi-import-models
description: >
  Populate ~/.pi/agent/models.json by importing the model catalog from an
  OpenAI-compatible /v1/models endpoint. Use when the user has added a new
  provider entry with just api/baseUrl/apiKey and wants the full model list
  pulled from upstream, or when an existing provider's catalog has changed
  (new models, new pricing, removed models). Trigger on: "import models",
  "sync pi models", "resync provider", "fetch catalog", "add all models
  from <provider>", "populate models.json from /v1/models", "refresh
  pricing", or any request to bulk-import a provider's model list into
  pi's config.
---

# pi Import Models

Populate `~/.pi/agent/models.json` from an OpenAI-compatible `/v1/models` catalog.

## When to Use

- A provider entry exists in `~/.pi/agent/models.json` with auth (`api`, `baseUrl`, `apiKey`) but no `models` array, and the user wants it filled in.
- An existing provider needs to be resynced against the upstream catalog (new models, price changes, removals).
- The user explicitly names a provider and asks to fetch its full model list.

## When NOT to Use

- Adding a single model → do it manually.
- The endpoint is not OpenAI-compatible (no `/v1/models` returning `{object: "list", data: [...]}`) → abort and tell the user to find provider-specific docs.
- The user wants to edit a specific model's `thinkingLevelMap`, `maxTokens`, or `compat` → those live under `modelOverrides`, not in this skill.

## Secret Handling

The provider's `apiKey` lives in `~/.pi/agent/models.json` as an env var reference (e.g. `"$INCO_API_KEY"`). The agent's shell resolves it at call time.

### What is and isn't exposed

| Surface | Exposure |
|---|---|
| `~/.pi/agent/models.json` on disk / in git | Safe — only the env var reference, never the real key |
| `curl`'s argv (visible to `ps aux`, process accounting) | **Avoided** — we never put the key on curl's command line |
| Bash tool command transcript | **Partially mitigated** — the shell still has to expand `$INCO_API_KEY` once; the resulting value is written to a 0600 file, then unset. Whether the bash tool captures expanded vs raw form is implementation-specific; assume worst case. |
| `ps` during the brief `printf` write | Brief window; key not in any other process's argv |
| Temp file with the key | 0600 perms, owned by the current user, deleted immediately after use |

### Hardened fetch pattern (default)

The key is resolved into a shell variable, written to a 0600 curl config file, then `unset`. `curl` reads the header from the file (path only on argv) and the file is deleted:

```bash
baseUrl=$(jq -r '.providers.<id>.baseUrl' ~/.pi/agent/models.json | sed 's:/*$::')
apiKeyRef=$(jq -r '.providers.<id>.apiKey' ~/.pi/agent/models.json)

# Resolve env var: models.json stores e.g. "$INCO_API_KEY", we want the value.
envName=${apiKeyRef#$}
apiKey="${!envName:-}"

if [ -z "$apiKey" ]; then
  echo "Env var $envName is unset. Export it in the pi session and retry." >&2
  exit 2
fi

cfg=$(mktemp -t pi-curl-cfg.XXXXXX)
chmod 600 "$cfg"
umask 077
printf 'header = "Authorization: Bearer %s"\n' "$apiKey" > "$cfg"
unset apiKey

status=$(curl -sS -K "$cfg" \
  -o /tmp/pi-import-catalog.json \
  -w "%{http_code}" \
  "$baseUrl/models")

rm -f "$cfg"
```

Why this is safer than `-H "Authorization: Bearer $KEY"`:
- `curl`'s argv contains only the config file path, not the key.
- `ps aux` / process accounting won't show the key.
- The temp file has `0600` perms; only the current user can read it.
- The key is unset from the shell immediately after the file write.

What this does NOT protect:
- If the bash tool logs the expanded command, the key may still appear in the transcript. This is a property of the bash tool itself; for true zero-transcript exposure, the key should never live in the agent's environment at all (use a sidecar proxy or a tool that injects auth headers).

## Workflow

### 1. Locate the target provider

Read `~/.pi/agent/models.json` and find `providers.<id>`. If it does not exist, stop and ask the user to add it first with at minimum `api: "openai-completions"`, `baseUrl`, and `apiKey` (env-var form like `"$INCO_API_KEY"` is fine).

Normalize `baseUrl`: strip trailing `/`, ensure path ends in `/v1`. The catalog URL is `{baseUrl}/models`.

### 2. Fetch the catalog

Use the hardened fetch pattern from the **Secret Handling** section above. It resolves the env var, writes to a 0600 curl config file, runs curl with the key never on argv, then deletes the file.

Response requirements:
- HTTP 200
- Top-level `object: "list"` with `data: [...]`

Anything else → abort, show the actual response shape, do not proceed.

### 3. Map fields

Standard `/v1/models` entry → pi model entry:

| Catalog field | pi `models.json` field | Notes |
|---|---|---|
| `data[i].id` | `models[i].id` | pass through |
| `data[i].name` | `models[i].name` | pass through |
| `data[i].context_length` | `models[i].contextWindow` | required |
| `data[i].pricing.input` | `models[i].cost.input` | USD per 1M tokens |
| `data[i].pricing.output` | `models[i].cost.output` | |
| `data[i].pricing.cached_input` | `models[i].cost.cacheRead` | OpenAI naming |
| — | `models[i].cost.cacheWrite` | always `0` unless provider publishes one |
| `data[i].capabilities.reasoning_effort == true` | `models[i].reasoning: true` | omit if false/undefined |
| `data[i].modalities.input` | `models[i].input` | emit `["text", "image"]` only if `"image"` is present; drop unknown types |
| `data[i].pricing: null` | omit `cost` entirely | warn — pi will default to zeros |

Fields the skill never invents:
- `thinkingLevelMap` — pi-specific; user opts in via `modelOverrides`
- `maxTokens` — leave unset (pi default 16384) unless provider docs mandate otherwise
- `tool_call` / `structured_output` — pi detects from API responses
- `cacheWrite` rate — only set if catalog returns one

If `context_length` is missing on a model, default to `128000` and warn the user that pi will use the documented default.

### 4. Preserve, do not touch

The edit MUST keep intact everything outside the `models` array:
- `api`, `apiKey`, `baseUrl`, `headers`
- `compat` (provider-level)
- `modelOverrides`
- All other providers

The skill only replaces `providers.<id>.models`.

### 5. Confirm with the user

Before writing, show:
- Provider id being updated
- Number of models being added (and any removed, if the catalog no longer lists a previously-imported id)
- Sample of 1–2 model entries (cheapest, multimodal, reasoning)
- Explicit warning: **"This REPLACES the models array. Per-model custom fields (thinkingLevelMap, maxTokens, custom compat) are wiped. Migrate them into providers.<id>.modelOverrides first if you want to keep them."**

If the user wants merge mode (keep existing entries, only add new), do it as a second pass after confirmation.

### 6. Write

Use the `edit` tool with surgical `oldText`/`newText`. The cleanest anchor is the existing `"models": [ ... ]` array under the target provider — replace the whole array in one shot.

If the array doesn't exist yet (new provider with only auth), insert it after the last known key in the provider block.

### 8. Validate

```bash
python3 -c "import json; json.load(open('/Users/ball6847/.pi/agent/models.json'))" && echo OK
```

Then print a summary:

```bash
python3 -c "
import json
p = json.load(open('/Users/ball6847/.pi/agent/models.json'))['providers']['<id>']
ms = p.get('models', [])
print(f'Provider <id>: {len(ms)} models')
for m in ms:
    c = m.get('cost', {})
    flags = ('R' if m.get('reasoning') else ' ') + ('I' if 'image' in (m.get('input') or []) else ' ')
    print(f'  {m[\"id\"]:40s} ctx={m.get(\"contextWindow\",\"?\"):>7}  in={c.get(\"input\",0):>7}  out={c.get(\"output\",0):>7}  cr={c.get(\"cacheRead\",0)}  {flags}')
"
```

## Examples

### Example 1: bootstrap a new provider

User: "I just added `groq` to models.json. Import its models."

1. `jq '.providers.groq'` → `{api: "openai-completions", baseUrl: "https://api.groq.com/openai/v1", apiKey: "$GROQ_API_KEY"}`
2. `curl https://api.groq.com/openai/v1/models` → ~20 models.
3. Map, set `reasoning` from capabilities, set `input` from modalities.
4. Show summary, ask "Proceed with REPLACE? (yes/no)".
5. Replace `providers.groq.models` with the catalog.

### Example 2: resync inco-ai pricing

User: "inco-ai pricing changed, resync."

1. Detect that `providers.inco-ai` has 10 existing models with `thinkingLevelMap` on each.
2. Warn: "Your 10 models each have a custom thinkingLevelMap. They will be lost unless you migrate them into `modelOverrides` now. Want me to (a) capture all 10 into `modelOverrides.<id>.thinkingLevelMap` first, then replace, or (b) just replace?"
3. If (a): first do a sed/jq pass to copy `thinkingLevelMap` from each model into `modelOverrides`, then replace. (b): replace directly.
4. Re-validate.

### Example 3: auth failure

1. `curl` returns 401. Body says `{"error": "missing api key"}`.
2. Stop. Tell user:
   > "The catalog endpoint at `https://api.foo.bar/v1/models` returned 401. Auth is required. Confirm `apiKey` is set in `providers.<id>` and that the env var (`$FOO_API_KEY` or similar) is exported in the pi session."

### Example 4: non-standard catalog shape

1. Response is `{`{"models": [...]}`}` (no `object: "list"`).
2. Stop. Show the actual shape. Tell user this skill targets OpenAI-compatible catalogs; for non-standard shapes they need a custom importer.

## Safety Rules

- **Never** modify `apiKey`, `baseUrl`, `api`, `headers`, `compat`, `modelOverrides`, or any sibling provider — only `providers.<id>.models`.
- **Never** silently merge. Default is REPLACE; require explicit confirmation.
- **Never** invent pricing. `pricing: null` → omit `cost` and warn.
- **Never** auto-add `thinkingLevelMap`, `maxTokens`, `tool_call`, or `structured_output`. Those are per-model customizations.
- **Never** proceed on non-200. Show the user the actual status and body.
- **Always** validate JSON after editing and print the summary table.

## Re-syncing safely

When invoked repeatedly for the same provider, the recommended loop is:

1. Capture any user-customized per-model fields into `modelOverrides` (one-time, then they survive future syncs).
2. Run the skill — it REPLACES `models` cleanly from the live catalog.
3. Validate.

After step 1, future syncs are lossless: `modelOverrides` is preserved by the skill's edit (it's outside the `models` array).