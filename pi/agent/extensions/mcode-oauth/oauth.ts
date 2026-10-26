/**
 * mcode device-code OAuth flow.
 *
 * Port of ~/.pi/agent/mcode-token.mjs / the mcode CLI's oauth-client.ts:
 *   POST {accountOrigin}/oauth2/device/code  -> device code
 *   POST {accountOrigin}/oauth2/token         -> tokens (device_code or refresh_token grant)
 *
 * Two server shapes are supported:
 *   1. standard RFC 8628  -> poll with `device_code`
 *   2. MiniMax account    -> no device_code, poll with `user_code` and `expired_in` in ms
 */
import { createHash, randomBytes } from "node:crypto";
import {
	DEVICE_GRANT_TYPE,
	MCODE_AUDIENCE,
	MCODE_CLIENT_ID,
	MCODE_SCOPES,
	type RegionConfig,
} from "./constants.ts";

export const LOGIN_CANCELLED_MESSAGE = "Login cancelled";
const REQUEST_TIMEOUT_MS = 15_000;

export interface McodeGrant {
	accessToken: string;
	refreshToken: string;
	tokenType: "Bearer";
	scopes: string[];
	audience: string;
	expiresInSec: number;
	expiresAtMs: number;
	subject?: string;
	accountId?: string;
}

export interface DeviceAuthorization {
	deviceCode: string;
	codeVerifier: string;
	/** Which field the token endpoint expects while polling. */
	pollParameter: "device_code" | "user_code";
	userCode: string;
	verificationUri: string;
	verificationUriComplete?: string;
	expiresInSec: number;
	intervalSec: number;
}

interface FormResponse {
	ok: boolean;
	status: number;
	body: Record<string, unknown>;
	error?: string;
}

/** Abort a request when the parent signal aborts or the timeout elapses. */
function withTimeout(signal: AbortSignal | undefined, ms: number) {
	const controller = new AbortController();
	const timer = setTimeout(() => controller.abort(new Error("timeout")), ms);
	const onAbort = () => controller.abort(signal?.reason);
	if (signal) {
		if (signal.aborted) onAbort();
		else signal.addEventListener("abort", onAbort, { once: true });
	}
	return {
		signal: controller.signal,
		dispose: () => {
			clearTimeout(timer);
			signal?.removeEventListener("abort", onAbort);
		},
	};
}

function isCancelled(signal?: AbortSignal): boolean {
	return Boolean(signal?.aborted);
}

function cancelled(): Error {
	return new Error(LOGIN_CANCELLED_MESSAGE);
}

function sleep(ms: number, signal?: AbortSignal): Promise<void> {
	return new Promise((resolve, reject) => {
		if (isCancelled(signal)) {
			reject(cancelled());
			return;
		}
		const timer = setTimeout(() => {
			signal?.removeEventListener("abort", onAbort);
			resolve();
		}, ms);
		function onAbort() {
			clearTimeout(timer);
			reject(cancelled());
		}
		signal?.addEventListener("abort", onAbort, { once: true });
	});
}

async function postForm(
	endpoint: string,
	values: Record<string, string>,
	signal?: AbortSignal,
): Promise<FormResponse> {
	const timeout = withTimeout(signal, REQUEST_TIMEOUT_MS);
	let response: Response;
	try {
		response = await fetch(endpoint, {
			method: "POST",
			headers: {
				Accept: "application/json",
				"Content-Type": "application/x-www-form-urlencoded",
			},
			body: new URLSearchParams(values),
			signal: timeout.signal,
		});
	} catch (error) {
		if (isCancelled(signal)) throw cancelled();
		const reason = signal?.aborted ? "timed out" : String(error);
		throw new Error(`mcode request to ${endpoint} failed: ${reason}`);
	} finally {
		timeout.dispose();
	}
	const raw = await response.text();
	let parsed: unknown;
	try {
		parsed = JSON.parse(raw);
	} catch {
		parsed = undefined;
	}
	if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
		return {
			ok: false,
			status: response.status,
			body: {},
			error: `non_json_response: ${raw.slice(0, 120)}`,
		};
	}
	const body = parsed as Record<string, unknown>;
	const error = typeof body.error === "string" ? body.error : undefined;
	return { ok: response.ok && !error, status: response.status, body, error };
}

function readString(obj: Record<string, unknown> | undefined, key: string): string | undefined {
	const value = obj?.[key];
	return typeof value === "string" && value.trim() ? value.trim() : undefined;
}

function readPositiveNumber(obj: Record<string, unknown> | undefined, key: string): number | undefined {
	const value = obj?.[key];
	return typeof value === "number" && Number.isFinite(value) && value > 0 ? value : undefined;
}

function decodeJwtPayload(token: string): Record<string, unknown> | undefined {
	const segments = token.split(".");
	if (segments.length !== 3 || !segments[1]) return undefined;
	try {
		const payload = JSON.parse(Buffer.from(segments[1], "base64url").toString("utf8"));
		return payload && typeof payload === "object" ? (payload as Record<string, unknown>) : undefined;
	} catch {
		return undefined;
	}
}

function parseScopes(value: unknown): string[] {
	if (typeof value === "string") return value.split(/\s+/u).filter(Boolean);
	if (Array.isArray(value) && value.every((entry) => typeof entry === "string")) return value as string[];
	return [];
}

/** Only accept a usable bearer token that carries the agent.default scope. */
export function parseTokenGrant(
	body: Record<string, unknown>,
	previousRefreshToken?: string,
	previousScopes?: string[],
): McodeGrant {
	const accessToken = readString(body, "access_token");
	const refreshToken = readString(body, "refresh_token") ?? previousRefreshToken;
	const tokenType = readString(body, "token_type");
	const expiresInSec = readPositiveNumber(body, "expires_in");
	const claims = accessToken ? decodeJwtPayload(accessToken) : undefined;
	// A refresh response may omit the scope; the previous grant still holds.
	const scopes = parseScopes(body.scope ?? claims?.scope ?? claims?.scp);
	const effectiveScopes = scopes.length > 0 ? scopes : (previousScopes ?? []);
	if (
		!accessToken ||
		!refreshToken ||
		tokenType?.toLowerCase() !== "bearer" ||
		!expiresInSec ||
		!effectiveScopes.includes(MCODE_SCOPES[0])
	) {
		throw new Error("mcode token response was not a usable bearer token");
	}
	const grant: McodeGrant = {
		accessToken,
		refreshToken,
		tokenType: "Bearer",
		scopes: effectiveScopes,
		audience: MCODE_AUDIENCE,
		expiresInSec,
		expiresAtMs: Date.now() + expiresInSec * 1000,
	};
	const subject = readString(claims, "sub");
	if (subject) grant.subject = subject;
	const accountId = readString(claims, "account_id");
	if (accountId) grant.accountId = accountId;
	return grant;
}

/** Only http(s) URLs are shown to the user or opened in a browser. */
export function trustedHttpUrl(value: unknown): string | undefined {
	if (typeof value !== "string" || !value.trim()) return undefined;
	try {
		const url = new URL(value);
		return url.protocol === "https:" || url.protocol === "http:" ? url.href : undefined;
	} catch {
		return undefined;
	}
}

/** The MiniMax account page expects these markers to render the code form. */
function markAuthorizationUrl(url: string): string {
	try {
		const parsed = new URL(url);
		parsed.searchParams.set("client_surface", "tui");
		parsed.searchParams.set("download_source", "mcode-internal");
		return parsed.toString();
	} catch {
		return url;
	}
}

/** The account variant reports the lifetime in milliseconds. */
function normalizeAccountExpiry(expiredIn: number | undefined): number | undefined {
	if (expiredIn === undefined) return undefined;
	if (expiredIn < 1_000_000_000_000) return expiredIn;
	const remainingMs = expiredIn - Date.now();
	return remainingMs > 0 ? Math.ceil(remainingMs / 1000) : undefined;
}

export async function startDeviceAuthorization(
	config: RegionConfig,
	signal?: AbortSignal,
): Promise<DeviceAuthorization> {
	if (isCancelled(signal)) throw cancelled();
	const codeVerifier = randomBytes(32).toString("base64url");
	const codeChallenge = createHash("sha256").update(codeVerifier, "ascii").digest("base64url");

	const { ok, status, body, error } = await postForm(
		`${config.accountOrigin}/oauth2/device/code`,
		{
			client_id: MCODE_CLIENT_ID,
			scope: MCODE_SCOPES.join(" "),
			audience: MCODE_AUDIENCE,
			code_challenge: codeChallenge,
			code_challenge_method: "S256",
		},
		signal,
	);
	if (!ok) {
		throw new Error(`mcode device authorization failed (HTTP ${status}): ${error ?? "unknown"}`);
	}

	const userCode = readString(body, "user_code");
	const standardDeviceCode = readString(body, "device_code");
	const accountExpiredAtMs = readPositiveNumber(body, "expired_in");
	const usesAccountUserCodePolling =
		!standardDeviceCode && Boolean(userCode) && accountExpiredAtMs !== undefined;
	const deviceCode = standardDeviceCode ?? (usesAccountUserCodePolling ? userCode : undefined);
	const verificationUri =
		trustedHttpUrl(body.verification_uri) ?? trustedHttpUrl(body.verification_url);
	const expiresInSec = readPositiveNumber(body, "expires_in") ?? normalizeAccountExpiry(accountExpiredAtMs);
	const rawInterval = readPositiveNumber(body, "interval");
	const intervalSec =
		usesAccountUserCodePolling && rawInterval !== undefined ? rawInterval / 1000 : (rawInterval ?? 5);

	if (!deviceCode || !userCode || !verificationUri || !expiresInSec) {
		throw new Error(
			`mcode device authorization response was incomplete (keys: ${Object.keys(body).join(", ")})`,
		);
	}

	const complete = trustedHttpUrl(body.verification_uri_complete);
	return {
		deviceCode,
		codeVerifier,
		pollParameter: usesAccountUserCodePolling ? "user_code" : "device_code",
		userCode,
		verificationUri: complete ? markAuthorizationUrl(complete) : markAuthorizationUrl(verificationUri),
		verificationUriComplete: complete ? markAuthorizationUrl(complete) : undefined,
		expiresInSec,
		intervalSec,
	};
}

export async function pollDeviceToken(
	config: RegionConfig,
	authorization: DeviceAuthorization,
	signal?: AbortSignal,
): Promise<McodeGrant> {
	const deadline = Date.now() + authorization.expiresInSec * 1000;
	let intervalMs = Math.max(1, authorization.intervalSec) * 1000;

	while (Date.now() < deadline) {
		if (isCancelled(signal)) throw cancelled();
		await sleep(intervalMs, signal);
		if (isCancelled(signal)) throw cancelled();

		const polling: Record<string, string> =
			authorization.pollParameter === "user_code"
				? { user_code: authorization.userCode }
				: { device_code: authorization.deviceCode };

		const { ok, status, body, error } = await postForm(
			`${config.accountOrigin}/oauth2/token`,
			{
				grant_type: DEVICE_GRANT_TYPE,
				...polling,
				client_id: MCODE_CLIENT_ID,
				code_verifier: authorization.codeVerifier,
			},
			signal,
		);

		const pollingStatus = readString(body, "status");
		if (ok && pollingStatus === "pending") continue;
		if (ok && pollingStatus === "slow_down") {
			intervalMs += 5_000;
			continue;
		}
		if (ok && (pollingStatus === "denied" || pollingStatus === "access_denied")) {
			throw new Error("mcode login was denied");
		}
		if (ok && (pollingStatus === "expired" || pollingStatus === "expired_token")) {
			throw new Error("mcode login request expired");
		}
		if (ok) return parseTokenGrant(body);

		if (error === "authorization_pending") continue;
		if (error === "slow_down") {
			intervalMs += 5_000;
			continue;
		}
		throw new Error(`mcode token request failed (HTTP ${status}): ${error ?? "unknown"}`);
	}
	throw new Error("mcode login request expired");
}

export async function refreshAccessToken(
	config: RegionConfig,
	refreshToken: string,
	signal?: AbortSignal,
	previousScopes?: string[],
): Promise<McodeGrant> {
	if (!refreshToken.trim()) {
		throw new Error("mcode refresh token is missing — run /login mcode again");
	}
	const { ok, status, body, error } = await postForm(
		`${config.accountOrigin}/oauth2/token`,
		{
			grant_type: "refresh_token",
			refresh_token: refreshToken,
			client_id: MCODE_CLIENT_ID,
			scope: MCODE_SCOPES.join(" "),
			audience: MCODE_AUDIENCE,
		},
		signal,
	);
	if (!ok) {
		const detail = error === "invalid_grant" ? "refresh token rejected" : (error ?? "unknown");
		throw new Error(`mcode refresh failed (HTTP ${status}): ${detail}`);
	}
	return parseTokenGrant(body, refreshToken, previousScopes);
}
