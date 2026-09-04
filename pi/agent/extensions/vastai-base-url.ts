/**
 * Injects the confidential Vast.ai instance endpoint into the `vastai`
 * provider declared in ~/.pi/agent/models.json.
 *
 * The models.json entry keeps its models / apiKey / compat; its baseUrl is a
 * placeholder (http://127.0.0.1:0/v1) that this extension overrides at runtime.
 *
 * Usage: export VASTAI_INSTANCE_API_URL=http://HOST:PORT/v1   (never committed/stored)
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  const url = process.env.VASTAI_INSTANCE_API_URL?.trim();
  if (!url) {
    console.warn(
      "[vastai-base-url] VASTAI_INSTANCE_API_URL is not set — vastai will be unreachable until it is exported.",
    );
    return;
  }
  pi.registerProvider("vastai", {
    name: "Vast.ai",
    baseUrl: url,
  });
}
