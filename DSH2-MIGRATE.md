# DSH (DeepSeek Harness) setup guide — repeatable on a fresh machine

Verified against **dsh 0.2.0-rc.2** (npm `latest` at time of writing), macOS + homebrew node.
Target: a working `dsh web` profile with pi-ai providers, ZenMux (both protocols), a
Xiaomi MiMo route, a local vLLM route, and a searchable model picker.

> **Rule for this file:** no API keys, no tokens, no session URLs, no hostnames that
> identify a machine. Only environment-variable _names_, package names, and public URLs.

---

## 1. Install dsh

```bash
npm install -g @deepseek-ai/dsh        # or pin: @deepseek-ai/dsh@0.2.0-rc.2
dsh --version
```

## 2. Create the web profile

```bash
mkdir -p ~/.dsh/profiles/web
```

`~/.dsh/profiles/web/package.json`:

```json
{
  "name": "dsh-profile-web",
  "private": true,
  "dependencies": {
    "@zenmux/dsh-plugins": "^0.1.16",
    "dsh-plugin-task-notification": "github:<org>/<repo>",
    "dsh-plugin-undo": "github:<org>/<repo>#<commit>"
  },
  "dsh": {
    "profile": {
      "bundles": [
        "@deepseek-ai/dsh-base",
        "@deepseek-ai/dsh-web-app",
        "@zenmux/dsh-plugins",
        "dsh-plugin-undo",
        "dsh-plugin-task-notification"
      ],
      "patchReload": "live"
    }
  }
}
```

Install the profile deps:

```bash
dsh plugin --profile web install     # forwards to pnpm in the profile dir
```

### Known conflict: do NOT install `dsh-mimo-adapter`

The pi-ai catalog now ships builtin provider routes (`xiaomi`, `xiaomi-token-plan-cn/ams/sgp`).
A third-party adapter that registers the same route causes a boot failure:

```
configurable provider "xiaomi" is already declared   (DUPLICATE_DIRECTORY)
```

Use the builtin route instead (section 4). If a plugin that claims an existing route is
required, it must register _before_ llm-pi-ai AND the route must not be in the catalog —
in practice: remove it.

## 3. Peer-compatibility exemptions (0.2 upgrade gate)

Plugins declaring peer deps on `^0.1.x` are skipped under a `0.2.x` runtime:

```
skipping profile bundle "@zenmux/dsh-plugins": ... is incompatible with dsh 0.2.0-rc.2
```

Grant an exact-version, explicit-risk exemption (re-run after every dsh upgrade and after
every plugin version bump — the exemption is keyed on _both_ exact versions):

```bash
dsh plugin --profile web allow-version "@zenmux/dsh-plugins@<ver>" --dsh-version <dsh-ver> --accept-risk
dsh plugin --profile web allow-version "dsh-plugin-undo@<ver>"      --dsh-version <dsh-ver> --accept-risk
```

Remove the line from the error message to get the exact `<pkg@ver>` to pass.
Revoke is not needed: a new dsh version invalidates the exemption automatically.

## 4. Provider configuration (`llm-pi-ai`)

### 4a. Where config lives (0.2.0 changed this)

| dsh version | Settings home                                                                                 |
| ----------- | --------------------------------------------------------------------------------------------- |
| ≤ 0.1.x     | `~/.dsh/settings.yaml` (top-level `llm-pi-ai:` section)                                       |
| 0.2.x       | **profile patch**: `~/.dsh/profiles/<profile>/cordis.patch.yml` as an `- id: llm-pi-ai` entry |

On the first 0.2.x boot, dsh migrates `settings.yaml` automatically: it renames the file to
`settings.yaml.imported` and writes each section into the profile patch.

**Known migration bug:** the `llm-pi-ai` section can fail the import silently and survive
only in `settings.yaml.imported`. Symptom: model routes vanish from the picker, ZenMux
falls back to the bundled catalog. Fix: write the entry into the profile patch yourself
(section 4d) and verify (section 6).

### 4b. Environment variables (names only — export these, never write values to config)

| Env var                         | Used by                                                                           |
| ------------------------------- | --------------------------------------------------------------------------------- |
| `XIAOMI_TOKEN_PLAN_SGP_API_KEY` | route `xiaomi-token-plan-sgp`                                                     |
| `XIAOMI_API_KEY`                | route `xiaomi` (mainland endpoint)                                                |
| `ZENMUX_OAUTH_ACCESS_TOKEN`     | ZenMux routes — **do not export manually**; created by `/zenmux login` in dsh web |
| `LLAMA_API_KEY`                 | local vLLM route (optional)                                                       |

pi-ai discovers builtin catalog routes from these names on its own; listing
`apiKeyEnv` in config makes the lookup explicit and lets the dsh credentials store win.

### 4c. Route types

- **Catalog route** (id exists in pi-ai's builtin catalog, e.g. `xiaomi-token-plan-sgp`):
  config needs only `apiKeyEnv`; models/baseURL/api come from the installed catalog.
  `models:` (if present) **replaces** the catalog list for that route — a bare `- id: x`
  entry inherits all fields from the catalog.
- **Declared route** (id NOT in the catalog, e.g. `zenmux`, `vllm`):
  every route-level field (`displayName`, `api`, `baseURL`, `apiKeyEnv`) must be present,
  and every model entry must spell out `contextWindow` / `input` / etc.

### 4d. Template — `cordis.patch.yml` entry

The patch file is a top-level YAML array. Entries with the same `id` from different layers
(bundles, profile) are composed; **the profile layer's `providers` dict must be
self-contained** — include the connection fields, not just `models`, or you get:

```
provider "zenmux" model "..." needs an api; the installed catalog does not describe it
```

```yaml
- id: llm-pi-ai
  name: "@deepseek-ai/dsh-llm-pi-ai"
  config:
    providers:
      # --- catalog route: apiKeyEnv is enough ---
      xiaomi-token-plan-sgp:
        apiKeyEnv: XIAOMI_TOKEN_PLAN_SGP_API_KEY

      # --- declared local route ---
      vllm:
        displayName: vLLM (local)
        apiKeyEnv: LLAMA_API_KEY
        api: openai-completions
        baseURL: https://<your-vllm-host>/v1
        models:
          - id: <model-id>
            name: <display name>
            contextWindow: 131072
            input: [text]
            reasoningEfforts:
              "off": null
              high: high

      # --- ZenMux, Anthropic protocol (fields copied from the bundle patch) ---
      zenmux:
        displayName: ZenMux · Anthropic
        baseURL: !!js >-
          process.env.ZENMUX_ANTHROPIC_BASE_URL ??
          `${new URL(process.env.ZENMUX_API_BASE_URL ?? 'https://zenmux.ai/api/v1').origin}/api/anthropic`
        api: anthropic-messages
        apiKeyEnv: ZENMUX_OAUTH_ACCESS_TOKEN
        cacheRetention: short
        thinkingBudgets:
          minimal: 1024
          low: 2048
          medium: 5120
          high: 10240
        models:
          - id: <vendor/model-id>
            name: <display name>
            contextWindow: 1000000
            input: [text, image]
            reasoningEfforts:
              "off": null
              high: high

      # --- ZenMux, OpenAI protocol ---
      zenmux-models:
        displayName: ZenMux · OpenAI
        baseURL: !!js >-
          process.env.ZENMUX_API_BASE_URL ?? 'https://zenmux.ai/api/v1'
        api: openai-completions
        apiKeyEnv: ZENMUX_OAUTH_ACCESS_TOKEN
        defaultContextWindow: 262144
        defaultMaxTokens: 32768
        defaultInput: [text]
        models:
          - id: <vendor/model-id>
            name: <display name>
            contextWindow: 1000000
            input: [text, image]
```

Full field reference: copy from the installed bundle patch
`<profile>/node_modules/@zenmux/dsh-plugins/cordis.patch.yml` (entries `- id: llm-pi-ai`
— keep everything except swap in your own `models:` list).

### 4e. Whitelisting models

A route's `models:` array is a **whitelist**: it fully replaces the catalog/bundle list.
Delete `- id: ...` blocks you don't want. Constraints:

- keep ≥ 1 model per route (empty list fails boot: `resolves no models`)
- never delete the `models:` key itself — that reverts to the bundled catalog (more models)
- edits go in the profile patch (or via Settings → Models, which writes the same file)

## 5. Other first-boot notices

- **Preview Notice dialog** on first 0.2 web load: click Continue.
- `/zenmux login` once in dsh web to mint `ZENMUX_OAUTH_ACCESS_TOKEN` (browser OAuth PKCE);
  `/zenmux status`, `/zenmux logout`.
- `EADDRINUSE 127.0.0.1:<port>` → a previous instance is still up:
  `lsof -nP -iTCP:<port> -sTCP:LISTEN` then kill it, or `dsh web --port <other>`.

## 6. Verify

```bash
# 1. composed tree parses and shows your providers (no secrets in output besides env names)
dsh --profile web --dump-config | grep -A3 "id: llm-pi-ai"

# 2. clean boot — no "skipping profile bundle", no EADDRINUSE
npx dsh web --port 3099 --no-open
```

In the web UI:

1. Composer → model picker opens; every expected provider group is listed with the right
   counts (missing group = its config failed to resolve; open Settings → Models for the
   exact error under the provider).
2. A **"Search models…"** box appears at the top of the picker (requires > 4 models;
   available from dsh 0.2). Type a few characters — the list filters across all groups.
3. Settings → Models: no error text under any provider.

## 7. Troubleshooting quick table

| Symptom                                                    | Cause                                                            | Fix                                                                                                  |
| ---------------------------------------------------------- | ---------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `configurable provider "x" is already declared` at boot    | third-party plugin + builtin catalog both claim route `x`        | remove the third-party plugin (section 2)                                                            |
| `skipping profile bundle "P": ... incompatible with dsh X` | peer deps pin an older runtime                                   | `dsh plugin --profile web allow-version P@ver --dsh-version X --accept-risk`                         |
| Providers/models missing after 0.2 upgrade                 | legacy `settings.yaml` migration dropped the `llm-pi-ai` section | write the entry into `cordis.patch.yml` (4d); check `~/.dsh/settings.yaml.imported` for the original |
| `provider "P" model "M" needs an api`                      | profile patch overrides the bundle's provider fields             | make the profile's provider entry self-contained (4d)                                                |
| `resolves no models`                                       | `models: []` on a route                                          | keep ≥ 1 model                                                                                       |
| Picker has no search box                                   | dsh < 0.2, or ≤ 4 models total                                   | upgrade / it appears automatically with more models                                                  |
| `listen EADDRINUSE`                                        | stale instance                                                   | section 5                                                                                            |

## 8. Repeat-on-a-new-machine checklist

1. `npm i -g @deepseek-ai/dsh@<ver>` → `dsh --version`
2. Copy/create profile (`package.json` bundles, `cordis.patch.yml`) — **do not copy
   `node_modules`**, run `dsh plugin --profile web install`
3. Export the env vars from 4b (or use `dsh` credentials store / `/zenmux login`)
4. Run the exemptions from section 3 for the exact dsh version
5. Section 6 verification (dump-config → boot → picker groups → search)
