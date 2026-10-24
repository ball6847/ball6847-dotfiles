/**
 * HTTP transport for the mcode provider.
 *
 * The account service rejects an access token that was rotated away: another
 * client (the `mcode` CLI, the MiniMax app, another pi session) refreshed the
 * session, or the token was revoked. pi only refreshes inside the 5-minute
 * expiry window, so a rejected token fails the request instead of recovering.
 *
 * The wrapper mints a fresh token and replays the request once.
 */
import type { FetchFunction } from "@earendil-works/pi-ai";

/** Returns a new access token, or undefined when no refresh is possible. */
export type TokenProvider = () => Promise<string | undefined>;

export function createRetryFetch(base: FetchFunction, nextToken: TokenProvider): FetchFunction {
	return async (input, init) => {
		const response = await base(input, init);
		if (response.status !== 401) return response;

		// A streamed request body cannot be replayed - do not try.
		if (init?.body && typeof init.body !== "string") return response;

		const token = await nextToken();
		// No new token: leave the response untouched so the caller can read the
		// error body.
		if (!token) return response;
		await response.body?.cancel().catch(() => undefined);

		const requestHeaders =
			init?.headers ??
			(typeof Request !== "undefined" && input instanceof Request ? input.headers : undefined);
		const headers = new Headers(requestHeaders as HeadersInit | undefined);
		headers.set("Authorization", `Bearer ${token}`);
		// The Anthropic adapter also sends the token as x-api-key.
		if (headers.has("x-api-key")) headers.set("x-api-key", token);

		if (typeof Request !== "undefined" && input instanceof Request) {
			return base(new Request(input, { headers }), init);
		}
		return base(input, { ...init, headers });
	};
}
