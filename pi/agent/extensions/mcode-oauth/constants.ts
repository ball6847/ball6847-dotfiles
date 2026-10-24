/**
 * MiniMax Code (mcode) OAuth constants.
 *
 * Mirrors the values used by the mcode CLI
 * (MiniMax-AI/minimax-code, packages/oauth-core/src/contracts.ts).
 */

export const MCODE_PROVIDER_ID = "mcode";
export const MCODE_PROVIDER_NAME = "MiniMax Code (mcode plan)";

/** Public client id used by the mcode CLI and the MiniMax Code app. */
export const MCODE_CLIENT_ID = "mcode-public";
export const MCODE_SCOPES = ["agent.default"];
export const MCODE_AUDIENCE = "agent-backend";
export const DEVICE_GRANT_TYPE = "urn:ietf:params:oauth:grant-type:device_code";

/** The CLI only ships a prod build; the namespace path keeps "prod" in it. */
export const BUILD_ENV = "prod";

export type McodeRegion = "en" | "cn";

export interface RegionConfig {
	region: McodeRegion;
	label: string;
	/** MiniMax account service that issues device codes and tokens. */
	accountOrigin: string;
	/** Anthropic-compatible endpoint that serves the mcode plan models. */
	apiBaseUrl: string;
}

export const REGION_CONFIG: Record<McodeRegion, RegionConfig> = {
	en: {
		region: "en",
		label: "Global (account.minimax.io)",
		accountOrigin: "https://account.minimax.io",
		apiBaseUrl: "https://agent.minimax.io/mavis/api/v1/llm",
	},
	cn: {
		region: "cn",
		label: "China (account.minimax.cn)",
		accountOrigin: "https://account.minimax.cn",
		apiBaseUrl: "https://agent.minimax.cn/mavis/api/v1/llm",
	},
};

export const DEFAULT_REGION: McodeRegion = "en";

/** Env overrides: MCODE_REGION (en|cn) and MCODE_API_BASE_URL. */
export function regionFromEnv(): McodeRegion | undefined {
	const raw = process.env.MCODE_REGION?.trim().toLowerCase();
	if (!raw) return undefined;
	if (raw === "cn" || raw === "china") return "cn";
	if (raw === "en" || raw === "global" || raw === "overseas") return "en";
	return undefined;
}

/**
 * API endpoint for a region.
 *
 * MCODE_API_BASE_URL can point the provider somewhere else. The access token
 * travels in the Authorization header of every request, so an override needs
 * MCODE_ALLOW_ENDPOINT_OVERRIDE=1 and an https URL (plaintext http is allowed
 * for loopback only).
 */
export function apiBaseUrlFor(region: McodeRegion): string {
	const fallback = REGION_CONFIG[region].apiBaseUrl;
	const override = process.env.MCODE_API_BASE_URL?.trim();
	if (!override) return fallback;
	if (!endpointOverridesAllowed() || !isAllowedEndpoint(override)) return fallback;
	return override;
}

/** Overrides are opt-in: a stray env var must not move credentials. */
function endpointOverridesAllowed(): boolean {
	return process.env.MCODE_ALLOW_ENDPOINT_OVERRIDE?.trim() === "1";
}

/** https anywhere, plaintext http only for loopback. */
function isAllowedEndpoint(value: string): boolean {
	try {
		const url = new URL(value);
		if (url.protocol === "https:") return true;
		if (url.protocol !== "http:") return false;
		const host = url.hostname.toLowerCase();
		return host === "localhost" || host === "127.0.0.1" || host === "[::1]" || host === "::1";
	} catch {
		return false;
	}
}

/**
 * Account service endpoints.
 *
 * MCODE_ACCOUNT_BASE_URL points the device-code and token endpoints somewhere
 * else — the token endpoint receives the refresh token and the PKCE verifier,
 * so the override is ignored unless MCODE_ALLOW_ENDPOINT_OVERRIDE=1 opts in
 * explicitly.
 */
export function regionConfig(region: McodeRegion): RegionConfig {
	const base = REGION_CONFIG[region] ?? REGION_CONFIG[DEFAULT_REGION];
	const override = endpointOverridesAllowed()
		? process.env.MCODE_ACCOUNT_BASE_URL?.trim()
		: undefined;
	return override && isAllowedEndpoint(override) ? { ...base, accountOrigin: override } : base;
}
