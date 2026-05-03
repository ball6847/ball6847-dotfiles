---
name: modellens-opencode
description: >
  Add AI models from ModelLens catalog directly to config/opencode/opencode.jsonc.
  Use this skill whenever the user wants to discover, compare, or add LLM models to their opencode configuration.
  Trigger on: "add models to opencode", "ModelLens", "find models for opencode", "add gpt-4", "update opencode models", or any request to manage models in opencode.jsonc.
---

# ModelLens to opencode.jsonc

You are an expert at integrating AI models from ModelLens into opencode.jsonc configuration.

## When to Use
- User wants to add new models to their opencode config
- User wants to find models matching specific criteria (provider, capabilities, cost, context size)
- User mentions ModelLens or wants to discover available models

## Workflow

### Step 1: Understand Requirements
Ask clarifying questions if needed:
- Which provider(s)? (openai, anthropic, mistral, etc.)
- Required capabilities? (tool_call, reasoning, attachment, structured_output)
- Cost constraints? (max input/output price per 1M tokens)
- Context window requirements?
- Sort by? (release_date, cost, context size)

If user gives vague request like "add good models", suggest categories:
- **Coding**: models with tool_call, high context
- **Reasoning**: models with reasoning capability
- **Cheap**: models under $5/1M tokens
- **High-context**: models with >100k context

### Step 2: Query ModelLens API

Use the ModelLens API base URL: `https://modellens.ball6847.deno.net/api`

**Get providers:**
```
GET /api/providers
```

**Get models with filters:**
```
GET /api/models?provider={provider}&query={search}&limit={limit}&offset={offset}&sort_by={field}&sort_dir={asc|desc}
```

Available query parameters:
- `provider`: Filter by provider ID (from /api/providers)
- `query`: Search by keyword in id, name, family
- `sort_by`: name, release_date, last_updated
- `sort_dir`: asc, desc
- `limit`: 1-1000 (default 100)
- `offset`: for pagination

### Step 3: Map ModelLens Providers to opencode Providers

Read the current opencode.jsonc first to understand existing providers:
```bash
read_file(path: "~/.dotfiles/config/opencode/opencode.jsonc")
```

Match ModelLens `provider_id` to opencode provider identities by comparing:
1. Exact `id` match
2. Exact `name` match  
3. Similar name (case-insensitive)

**If exact match exists**: Add model to that provider's `models` object
**If no match**: Ask user which existing provider to add to, or offer to create new provider block

### Step 4: Transform ModelLens Model to opencode Format

ModelLens returns fields that map directly to opencode. Copy these fields as-is:

```json
{
  "id": "model-id",                    // Model identifier
  "name": "Model Name",               // Human-readable name
  "family": "gpt",                     // Model family
  "attachment": true/false,           // Supports attachments
  "reasoning": true/false,            // Supports reasoning
  "tool_call": true/false,             // Supports tool calls
  "structured_output": true/false,    // Supports structured output
  "temperature": true/false,          // Supports temperature
  "knowledge": "2024-03",              // Knowledge cutoff
  "modalities": { "input": [...], "output": [...] }, // Input/output modalities
  "open_weights": true/false,          // Open weights
  "cost": { "input": 1.5, "output": 3.0, "cache_read": 0.1, "cache_write": 0.1 }, // Pricing
  "limit": { "context": 128000, "output": 4096, "input": 128000 }, // Token limits
  "interleaved": { "field": "reasoning_content" },   // Interleaved reasoning field
  "release_date": "2024-01-01",        // Release date
  "last_updated": "2024-01-01"         // Last update date
}
```

**opencode model entry format:**
```json
"model-id": {
  "id": "model-id",
  "name": "Model Name",
  "family": "gpt",
  "attachment": true,
  "reasoning": false,
  "tool_call": true,
  "structured_output": true,
  "temperature": true,
  "knowledge": "2024-03",
  "modalities": { "input": ["text"], "output": ["text"] },
  "cost": { "input": 1.5, "output": 3.0 },
  "limit": { "context": 128000, "output": 4096 }
}
```

### Step 5: Edit opencode.jsonc

**ALWAYS** read the current opencode.jsonc first:
```bash
read_file(path: "~/.dotfiles/config/opencode/opencode.jsonc")
```

**Add models to existing provider:**
Find the provider block and add to its `models` object using `search_replace`:

```json
"provider": {
  "mistral": {
    "id": "mistral",
    "models": {
      "existing-model": { ... },
      "new-model-id": { ... }  // ADD HERE
    }
  }
}
```

**Create new provider if needed:**
Only if user confirms and no matching provider exists:
```json
"provider": {
  "existing": { ... },
  "new-provider-id": {
    "id": "new-provider-id",
    "models": {
      "model-id": { ... }
    }
  }
}
```

### Step 6: Present Changes

Show the user:
1. Models found from ModelLens
2. Where they will be added in opencode.jsonc
3. The exact JSON that will be inserted
4. Ask for confirmation before writing

**ALWAYS ask for confirmation** before modifying opencode.jsonc:
> "I found X models matching your criteria. I will add them to the `provider-name` provider in opencode.jsonc. Here's what will be added:
>
> [show JSON diff]
>
> Proceed? (yes/no)"

If user says yes, use `search_replace` to modify the file.

### Step 7: Verify

After editing, verify the file is valid JSONC:
```bash
bash("command": "python3 -m json.tool ~/.dotfiles/config/opencode/opencode.jsonc > /dev/null 2>&1 && echo 'Valid JSON' || echo 'Invalid JSON'")
```

## Examples

**Example 1: User requests specific model**

User: "add gpt-4 to opencode"

1. Query ModelLens: `GET /api/models?query=gpt-4`
2. Find model(s) matching gpt-4
3. Match provider (openai)
4. Check if openai provider exists in opencode.jsonc
5. If not: "No 'openai' provider found. Available providers: mistral, ollama-cloud, synthetic. Add to which provider?"
6. Add model to selected provider
7. Confirm with user
8. Edit file

**Example 2: User requests models with criteria**

User: "find models with context > 100k and tool_call support, add the cheapest 5"

1. Query all models (handle pagination)
2. Filter: `limit.context > 100000` AND `tool_call == true`
3. Sort by cost (input + output)
4. Take top 5 cheapest
5. Group by provider and match to opencode providers
6. For each: show model and ask if user wants to add it
7. Add confirmed models
8. Edit file

**Example 3: User requests all models from provider**

User: "add all mistral models to opencode"

1. Query: `GET /api/models?provider=mistral`
2. Find opencode provider with id="mistral" (exists in user's config)
3. For each model, transform to opencode format
4. Show all models to be added
5. Ask for confirmation
6. Use search_replace to add all models at once
7. Verify

## Important Rules

- NEVER modify provider-level config (npm, options, baseURL, env, api) - only models
- NEVER remove existing models or providers
- ALWAYS preserve comments in opencode.jsonc (it's JSONC, not JSON)
- ALWAYS ask for confirmation before writing
- Use search_replace with exact JSON to avoid formatting issues
- Handle pagination if >100 results expected
- If user says "add to opencode" without specification, ask for clarification
- When adding to non-existent provider, always ask user which existing provider or create new
