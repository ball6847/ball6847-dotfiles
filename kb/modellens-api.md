# ModelLens API Documentation

> Base URL: `https://modellens.ball6847.deno.net`
>
> CORS: Enabled (`access-control-allow-origin: *`)
>
> Auth: None required
>
> Format: JSON

A read-only catalog API for discovering AI models and providers. No authentication or rate limits are enforced.

---

## Endpoints

### 1. List Providers

```
GET /api/providers
```

Returns a JSON array of all supported provider IDs.

**Response:**

```json
["openai", "anthropic", "google", "groq", "deepseek", "github-models", "azure", "bedrock", ...]
```

**Status Codes:**

- `200` - Success

---

### 2. List Models

```
GET /api/models
```

Returns a paginated list of AI models with detailed metadata.

**Query Parameters:**

| Parameter  | Type    | Required | Description                                                             |
| ---------- | ------- | -------- | ----------------------------------------------------------------------- |
| `query`    | string  | No       | Search/filter models by keyword (matches `id`, `name`, `family`)        |
| `provider` | string  | No       | Filter by provider ID (use `/api/providers` to get valid IDs)           |
| `sort_by`  | string  | No       | Field to sort by. Common values: `name`, `release_date`, `last_updated` |
| `sort_dir` | string  | No       | Sort direction: `asc` or `desc` (default: `asc`)                        |
| `offset`   | integer | No       | Pagination offset (0-based)                                             |
| `limit`    | integer | No       | Max results per page. Default appears to be `100`                       |

**Response Schema:**

```json
{
  "models": [
    {
      "id": "string",              // Model identifier (often provider-specific)
      "name": "string",            // Human-readable name
      "family": "string",          // Model family (e.g., "gpt", "claude", "llama")
      "provider_id": "string",     // Provider slug
      "attachment": boolean,       // Supports file attachments?
      "reasoning": boolean,        // Supports reasoning/thinking tokens?
      "tool_call": boolean,        // Supports function calling/tools?
      "structured_output": boolean,// Supports JSON schema / structured output?
      "temperature": boolean,      // Supports temperature parameter?
      "knowledge": "string",       // Knowledge cutoff date (YYYY-MM-DD or YYYY-MM)
      "release_date": "string",    // Initial release date
      "last_updated": "string",    // Last model update date
      "modalities": {
        "input": ["text", "image", "audio", "video"],
        "output": ["text", "image", "audio", "video"]
      },
      "open_weights": boolean,     // Is the model open-weight?
      "cost": {
        "input": number,           // Input cost per 1M tokens (USD)
        "output": number,          // Output cost per 1M tokens (USD)
        "cache_read": number,      // Cache read cost (if applicable)
        "cache_write": number      // Cache write cost (if applicable)
      },
      "limit": {
        "context": number,         // Max context window (tokens)
        "output": number,          // Max output tokens
        "input": number            // Max input tokens (if different from context)
      },
      "interleaved": {             // Present only for some reasoning models
        "field": "reasoning_content" // Field name where reasoning is interleaved
      }
    }
  ],
  "total": 4448                  // Total number of models in the catalog
}
```

**Notes:**

- Not all fields are present on every model. Check for existence before use.
- `cost` values of `0` usually indicate "free" or "pricing unavailable".
- `knowledge` may be a partial date string like `"2024-03"`.

**Status Codes:**

- `200` - Success
- `4xx/5xx` - Server error (rare)

---

## Examples

### Get all models (first 100)

```bash
curl -s 'https://modellens.ball6847.deno.net/api/models'
```

### Filter by provider

```bash
curl -s 'https://modellens.ball6847.deno.net/api/models?provider=anthropic'
```

### Search models

```bash
curl -s 'https://modellens.ball6847.deno.net/api/models?query=gpt-4&limit=10'
```

### Paginate through results

```bash
curl -s 'https://modellens.ball6847.deno.net/api/models?offset=100&limit=50'
```

### Sort by release date (newest first)

```bash
curl -s 'https://modellens.ball6847.deno.net/api/models?sort_by=release_date&sort_dir=desc&limit=20'
```

---

## Common Provider IDs

Some frequently used provider IDs from `/api/providers`:

| Provider      | ID               |
| ------------- | ---------------- |
| OpenAI        | `openai`         |
| Anthropic     | `anthropic`      |
| Google        | `google`         |
| Google Vertex | `google-vertex`  |
| Groq          | `groq`           |
| DeepSeek      | `deepseek`       |
| Mistral       | `mistral`        |
| Cohere        | `cohere`         |
| Azure OpenAI  | `azure`          |
| AWS Bedrock   | `amazon-bedrock` |
| Fireworks AI  | `fireworks-ai`   |
| Together AI   | `togetherai`     |
| Perplexity    | `perplexity`     |
| XAI (Grok)    | `xai`            |
| GitHub Models | `github-models`  |
| Hugging Face  | `huggingface`    |
| Ollama Cloud  | `ollama-cloud`   |
| OpenRouter    | `openrouter`     |

> Always call `/api/providers` to get the current full list — new providers are added regularly.
