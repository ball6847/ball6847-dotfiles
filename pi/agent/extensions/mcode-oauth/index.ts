/**
 * mcode (MiniMax Code plan) OAuth provider for pi.
 *
 * Registers the `mcode` provider (id unchanged, so `enabledModels: ["mcode/*"]`
 * keeps matching) with pi's built-in OAuth support:
 *
 *   /login mcode   -> device-code login against the MiniMax account service
 *   /mcode-status  -> region, token expiry, mirror location
 *
 * Token handling:
 *   - pi owns the canonical credential (its credential store, auth.json, mode
 *     0600) and calls refreshToken() when the access token is close to expiry.
 *   - every login/refresh is mirrored into the mcode CLI store
 *     (~/.minimax/auth/<env>/<region>/mcode-public/auth.json, 0600) so the
 *     `mcode` CLI and ~/.pi/agent/mcode-token.mjs keep working.
 *
 * The provider is OAuth-only: models.json keeps the model catalog, the
 * extension owns baseUrl / api / authHeader. No apiKey means `/login mcode`
 * goes straight to the browser instead of an auth-type menu.
 */
import type { ExtensionAPI, ProviderConfig } from "@earendil-works/pi-coding-agent";
import type { OAuthCredentials, OAuthLoginCallbacks } from "@earendil-works/pi-ai";
import { anthropicMessagesApi } from "@earendil-works/pi-ai/compat";
import {
	apiBaseUrlFor,
	DEFAULT_REGION,
	MCODE_PROVIDER_ID,
	MCODE_PROVIDER_NAME,
	REGION_CONFIG,
	regionConfig,
	regionFromEnv,
	type McodeRegion,
} from "./constants.ts";
import {
	LOGIN_CANCELLED_MESSAGE,
	pollDeviceToken,
	refreshAccessToken,
	startDeviceAuthorization,
	type McodeGrant,
} from "./oauth.ts";
import { cliNamespace, readCliCredential, saveToCliStore } from "./store.ts";
import { createRetryFetch } from "./transport.ts";
import { MCODE_MODELS } from "./models.ts";

/** Mirroring into the CLI store can be disabled with MCODE_MIRROR_CLI=0. */
function mirroringEnabled(): boolean {
	return process.env.MCODE_MIRROR_CLI?.trim() !== "0";
}

let registeredRegion: McodeRegion | undefined;
let extensionApi: ExtensionAPI | undefined;

/**
 * The freshest grant this process knows about.
 *
 * pi's credential store holds the canonical token, but a 401 retry mints a new
 * one that pi does not know about yet. getApiKey() hands this token to pi so
 * the next request does not repeat the failed round trip.
 */
let latestGrant: McodeGrant | undefined;

/** Region the provider is currently registered for. */
async function detectRegion(): Promise<McodeRegion> {
	const fromEnv = regionFromEnv();
	if (fromEnv) return fromEnv;
	let best: McodeRegion | undefined;
	let bestExpiry = 0;
	for (const region of ["en", "cn"] as McodeRegion[]) {
		const credential = await readCliCredential(region).catch(() => undefined);
		if (credential && credential.expiresAtMs > bestExpiry) {
			best = region;
			bestExpiry = credential.expiresAtMs;
		}
	}
	return best ?? DEFAULT_REGION;
}

const anthropic = anthropicMessagesApi();

/**
 * Mint a new access token after the server rejected the current one.
 *
 * The mirror store holds the freshest rotated refresh token (the `mcode` CLI
 * writes the same file), so it is tried first; the in-memory grant is the
 * fallback when mirroring is disabled.
 */
let refreshInFlight: Promise<string | undefined> | undefined;

async function forceRefreshToken(): Promise<string | undefined> {
	if (refreshInFlight) return refreshInFlight;
	refreshInFlight = (async () => {
		const region = registeredRegion ?? DEFAULT_REGION;
		const config = regionConfig(region);
		const stored = await readCliCredential(region).catch(() => undefined);
		const candidates = [stored?.refreshToken, latestGrant?.refreshToken].filter(
			(value): value is string => Boolean(value),
		);
		for (const refreshToken of new Set(candidates)) {
			try {
				const grant = await refreshAccessToken(
					config,
					refreshToken,
					undefined,
					stored?.scopes ?? latestGrant?.scopes,
				);
				latestGrant = grant;
				await mirror(grant, region);
				return grant.accessToken;
			} catch {
				// Try the next candidate refresh token.
			}
		}
		return undefined;
	})();
	try {
		return await refreshInFlight;
	} finally {
		refreshInFlight = undefined;
	}
}

/**
 * Replay a request that the account service answered with 401.
 *
 * The token was rotated away or revoked - pi would not recover on its own
 * because it only refreshes inside the 5-minute expiry window.
 */
function providerFetch(base: typeof globalThis.fetch) {
	return createRetryFetch(base, forceRefreshToken);
}

function providerConfig(region: McodeRegion): ProviderConfig {
	return {
		name: MCODE_PROVIDER_NAME,
		baseUrl: apiBaseUrlFor(region),
		api: "anthropic-messages",
		authHeader: true,
		// The catalog lives in the extension: pi-web's Models panel rewrites
		// models.json and would otherwise leave the provider without models.
		models: MCODE_MODELS,
		// Same Anthropic adapter pi uses, but with a transport that recovers
		// from a rejected access token.
		streamSimple: (model, context, options) =>
			anthropic.streamSimple(model, context, {
				...options,
				fetch: providerFetch(options?.fetch ?? globalThis.fetch),
			}),
		oauth: {
			name: MCODE_PROVIDER_NAME,
			isSubscription: true,
			login: loginMcode,
			refreshToken: refreshMcodeToken,
			// Prefer the in-memory grant when it is the newer of the two: a 401
			// retry mints a token that pi's credential store does not have yet.
			getApiKey: (credentials: OAuthCredentials) => {
				const grant = latestGrant;
				if (!grant) return credentials.access;
				if (typeof credentials.expires === "number" && credentials.expires > grant.expiresAtMs) {
					return credentials.access;
				}
				return grant.accessToken;
			},
		},
	};
}

/** Point the provider at the right region after a login that changed it. */
async function applyRegion(region: McodeRegion): Promise<void> {
	if (!extensionApi || registeredRegion === region) return;
	registeredRegion = region;
	extensionApi.registerProvider(MCODE_PROVIDER_ID, providerConfig(region));
}

function toCredentials(grant: McodeGrant, region: McodeRegion): OAuthCredentials {
	const credentials: OAuthCredentials = {
		access: grant.accessToken,
		refresh: grant.refreshToken,
		expires: grant.expiresAtMs,
		region,
		scopes: grant.scopes,
		audience: grant.audience,
		expiresAtMs: grant.expiresAtMs,
	};
	if (grant.subject) credentials.subject = grant.subject;
	if (grant.accountId) credentials.accountId = grant.accountId;
	return credentials;
}

async function mirror(grant: McodeGrant, region: McodeRegion): Promise<void> {
	if (!mirroringEnabled()) return;
	try {
		await saveToCliStore(grant, region);
	} catch (error) {
		console.warn(
			`mcode: could not mirror the token to the CLI store: ${
				error instanceof Error ? error.message : String(error)
			}`,
		);
	}
}

/** onSelect is optional at runtime (older pi versions). */
async function pickOption(
	callbacks: OAuthLoginCallbacks,
	message: string,
	options: { id: string; label: string }[],
): Promise<string | undefined> {
	const onSelect = (callbacks as { onSelect?: OAuthLoginCallbacks["onSelect"] }).onSelect;
	if (typeof onSelect !== "function") return undefined;
	try {
		return await onSelect({ message, options });
	} catch {
		return undefined;
	}
}

async function pickRegion(callbacks: OAuthLoginCallbacks): Promise<McodeRegion> {
	const fromEnv = regionFromEnv();
	if (fromEnv) return fromEnv;
	const choice = await pickOption(callbacks, "mcode region", [
		{ id: "en", label: REGION_CONFIG.en.label },
		{ id: "cn", label: REGION_CONFIG.cn.label },
	]);
	return choice === "cn" ? "cn" : "en";
}

async function loginMcode(callbacks: OAuthLoginCallbacks): Promise<OAuthCredentials> {
	const signal = callbacks.signal;
	try {
		callbacks.onProgress?.("Resolving mcode region…");
		const region = await pickRegion(callbacks);
		const config = regionConfig(region);

		const existing = await readCliCredential(region).catch(() => undefined);
		if (existing && existing.expiresAtMs > Date.now() + 60_000) {
			const choice = await pickOption(callbacks, "mcode login method", [
				{ id: "reuse", label: "Reuse existing mcode session" },
				{ id: "device", label: "Sign in with a MiniMax account" },
			]);
			if (choice === "reuse") {
				callbacks.onProgress?.("Reusing the existing mcode session…");
				const grant: McodeGrant = {
					accessToken: existing.accessToken,
					refreshToken: existing.refreshToken,
					tokenType: "Bearer",
					scopes: existing.scopes.length > 0 ? existing.scopes : ["agent.default"],
					audience: "agent-backend",
					expiresInSec: Math.max(1, Math.floor((existing.expiresAtMs - Date.now()) / 1000)),
					expiresAtMs: existing.expiresAtMs,
				};
				await mirror(grant, region);
				await applyRegion(region);
				latestGrant = grant;
				return toCredentials(grant, region);
			}
		}

		callbacks.onProgress?.("Starting mcode device authorization…");
		const authorization = await startDeviceAuthorization(config, signal);
		callbacks.onDeviceCode({
			userCode: authorization.userCode,
			verificationUri: authorization.verificationUri,
			intervalSeconds: Math.max(1, Math.round(authorization.intervalSec)),
			expiresInSeconds: authorization.expiresInSec,
		});
		callbacks.onProgress?.("Waiting for mcode login approval…");
		const grant = await pollDeviceToken(config, authorization, signal);
		await mirror(grant, region);
		await applyRegion(region);
		latestGrant = grant;
		return toCredentials(grant, region);
	} catch (error) {
		if (signal?.aborted) throw new Error(LOGIN_CANCELLED_MESSAGE, { cause: error });
		throw error;
	}
}

async function refreshMcodeToken(
	credentials: OAuthCredentials,
	signal: AbortSignal,
): Promise<OAuthCredentials> {
	const region = (credentials.region as McodeRegion | undefined) ?? DEFAULT_REGION;
	const config = regionConfig(region);
	const current = typeof credentials.refresh === "string" ? credentials.refresh : "";
	const previousScopes = Array.isArray(credentials.scopes)
		? (credentials.scopes as string[])
		: undefined;
	try {
		const grant = await refreshAccessToken(config, current, signal, previousScopes);
		await mirror(grant, region);
		await applyRegion(region);
		latestGrant = grant;
		return toCredentials(grant, region);
	} catch (error) {
		if (signal?.aborted) throw error;
		// The mcode CLI may have rotated the refresh token; adopt its newer copy.
		const cli = await readCliCredential(region).catch(() => undefined);
		if (cli?.refreshToken && cli.refreshToken !== current) {
			try {
				const grant = await refreshAccessToken(config, cli.refreshToken, signal, previousScopes);
				await mirror(grant, region);
				await applyRegion(region);
				latestGrant = grant;
				return toCredentials(grant, region);
			} catch (recoveryError) {
				throw new Error(
					`mcode refresh failed — run /login mcode again (${
						recoveryError instanceof Error ? recoveryError.message : String(recoveryError)
					})`,
				);
			}
		}
		throw new Error(
			`mcode refresh failed — run /login mcode again (${
				error instanceof Error ? error.message : String(error)
			})`,
		);
	}
}

export default function mcodeOAuthProvider(pi: ExtensionAPI): void {
	extensionApi = pi;

	// The provider must exist before the session starts, so resolve the region
	// from the environment synchronously and refine it in the background.
	const region = regionFromEnv() ?? DEFAULT_REGION;
	registeredRegion = region;
	pi.registerProvider(MCODE_PROVIDER_ID, providerConfig(region));

	// Pick up the region of an existing CLI session once the store is readable.
	void detectRegion().then(async (detected) => {
		if (detected !== registeredRegion) await applyRegion(detected);
	});

	pi.registerCommand("mcode-status", {
		description: "Show the mcode (MiniMax Code) login status",
		handler: async (_args, ctx) => {
			const region = registeredRegion ?? DEFAULT_REGION;
			const credential = await readCliCredential(region).catch(() => undefined);
			const namespace = cliNamespace(region);
			const lines = [
				`region        : ${region} (${regionConfig(region).accountOrigin})`,
				`api base url  : ${apiBaseUrlFor(region)}`,
				`cli store     : ${namespace.credentialPath}`,
				`mirroring     : ${mirroringEnabled() ? "on" : "off (MCODE_MIRROR_CLI=0)"}`,
			];
			if (credential) {
				const expires = credential.expiresAtMs
					? new Date(credential.expiresAtMs).toISOString()
					: "unknown";
				lines.push(
					`access token  : present${
						credential.expiresAtMs && credential.expiresAtMs < Date.now()
							? " (expired — /login mcode)"
							: ""
					}`,
					`expires at    : ${expires}`,
				);
			} else {
				lines.push("access token  : none — run /login mcode");
			}
			ctx.ui.notify(lines.join("\n"), "info");
		},
	});
}
