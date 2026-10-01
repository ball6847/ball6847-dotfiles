/**
 * Injects the confidential Vast.ai instance credentials into the `vastai`
 * provider declared in ~/.pi/agent/models.json.
 *
 * The models.json entry keeps its models / compat; its baseUrl is an inert
 * placeholder (http://127.0.0.1:0/v1) and its apiKey is an env-var reference.
 * Both are overridden here at runtime — pi composes them as
 * `extension?.x ?? modelsJson?.x`, so the extension always wins.
 *
 * Resolution, first match wins:
 *   1. ~/.pi/agent/vastai-base-url.json — { "baseUrl": ..., "apiKey": ... }
 *   2. VASTAI_INSTANCE_API_URL           — baseUrl fallback when no file exists
 *
 * (1) is a real file in the agent dir, NOT a symlink into this dotfiles repo,
 * so the endpoint and key are structurally impossible to commit. See
 * vastai-base-url.example.json in this directory for the template.
 *
 * When nothing resolves, the provider is still registered — but every request
 * fails with an actionable message, instead of silently dialling the inert
 * 127.0.0.1:0 placeholder and surfacing a bare ECONNREFUSED.
 */
import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { getAgentDir } from "@earendil-works/pi-coding-agent";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const LOG = "vastai-base-url";
const CONFIG_FILE = `${LOG}.json`;
const PROVIDER_ID = "vastai";
/** Matches the models.json `api`, which pi requires before it will use streamSimple. */
const API = "openai-completions";
/** Unreachable on purpose; streamSimple throws before any socket is opened. */
const SENTINEL_BASE_URL = "http://127.0.0.1:0/v1";

type Resolved = { ok: true; baseUrl: string; apiKey?: string } | { ok: false; message: string };

function nonEmptyString(value: unknown): string | undefined {
  return typeof value === "string" && value.trim() ? value.trim() : undefined;
}

async function resolveConfig(): Promise<Resolved> {
  const path = join(getAgentDir(), CONFIG_FILE);

  let raw: string;
  try {
    raw = await readFile(path, "utf8");
  } catch (err) {
    if ((err as NodeJS.ErrnoException).code !== "ENOENT") {
      return { ok: false, message: `cannot read ${path}: ${(err as Error).message}` };
    }
    // No config file: the env var is the only remaining source, and it carries
    // a baseUrl only (apiKey still falls through to models.json's env reference).
    const fromEnv = nonEmptyString(process.env.VASTAI_INSTANCE_API_URL);
    if (fromEnv) return { ok: true, baseUrl: fromEnv };
    return {
      ok: false,
      message:
        `Vast.ai is not configured. Create ${path} containing ` +
        `{ "baseUrl": "http://HOST:PORT/v1", "apiKey": "sk-..." } ` +
        `(template: pi/agent/extensions/vastai-base-url.example.json in the dotfiles repo), ` +
        `or export VASTAI_INSTANCE_API_URL to supply just a baseUrl.`,
    };
  }

  let parsed: { baseUrl?: unknown; apiKey?: unknown };
  try {
    parsed = JSON.parse(raw) as { baseUrl?: unknown; apiKey?: unknown };
  } catch (err) {
    return { ok: false, message: `${path} is not valid JSON: ${(err as Error).message}` };
  }

  const baseUrl = nonEmptyString(parsed.baseUrl) ?? nonEmptyString(process.env.VASTAI_INSTANCE_API_URL);
  if (!baseUrl) {
    return {
      ok: false,
      message: `${path} has no non-empty "baseUrl" string (and VASTAI_INSTANCE_API_URL is not set).`,
    };
  }

  // No apiKey in the file is not fatal: models.json's "$LLAMA_API_KEY" still applies.
  const apiKey = nonEmptyString(parsed.apiKey);
  return apiKey ? { ok: true, baseUrl, apiKey } : { ok: true, baseUrl };
}

export default async function (pi: ExtensionAPI) {
  const resolved = await resolveConfig();

  if (!resolved.ok) {
    const message = `[${LOG}] ${resolved.message}`;
    console.warn(message);
    pi.registerProvider(PROVIDER_ID, {
      // Surfaced in the model picker, so a misconfigured provider is visible
      // before the user ever sends a request.
      name: "Vast.ai (not configured)",
      api: API,
      baseUrl: SENTINEL_BASE_URL,
      streamSimple: () => {
        throw new Error(message);
      },
    });
    return;
  }

  pi.registerProvider(PROVIDER_ID, {
    name: "Vast.ai",
    baseUrl: resolved.baseUrl,
    ...(resolved.apiKey ? { apiKey: resolved.apiKey } : {}),
  });
}
