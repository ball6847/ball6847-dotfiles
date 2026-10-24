# mcode OAuth provider (pi extension)

Registers the `mcode` provider (MiniMax Code plan) with pi's built-in OAuth
support, so `/login mcode` authorizes through the browser and pi refreshes
the token on its own.

## Layout

| File | Purpose |
| --- | --- |
| `index.ts` | Provider registration, `/login` + refresh wiring, `/mcode-status` |
| `oauth.ts` | Device-code flow + refresh-token grant against the MiniMax account service |
| `store.ts` | Mirror into the mcode CLI credential store (`~/.minimax/auth/...`, 0600) |
| `models.ts` | The model catalog (`MiniMax-M3.1-Flash`, `MiniMax-M3`) |
| `constants.ts` | Client id, scopes, regions, endpoints |

## Token storage

- **Canonical**: pi's own credential store (`~/.pi/agent/auth.json`, mode 0600).
  pi calls `refreshToken()` when the access token is within 5 minutes of expiry
  and writes the rotated token back under the store lock.
- **Mirror**: every login/refresh also writes the mcode CLI's record shape into
  `~/.minimax/auth/prod/<region>/mcode-public/auth.json` (atomic, 0600), so the
  `mcode` CLI and `~/.pi/agent/mcode-token.mjs` keep working.
  Disable with `MCODE_MIRROR_CLI=0`.

If the CLI rotates the refresh token first, `refreshToken()` picks the newer
copy from the CLI store instead of failing.

## Environment overrides

| Variable | Meaning |
| --- | --- |
| `MCODE_REGION` | `en` (global) or `cn` — skips the region prompt |
| `MCODE_API_BASE_URL` | Override the Anthropic-compatible endpoint (needs the opt-in below) |
| `MCODE_ACCOUNT_BASE_URL` | Override the MiniMax account origin (needs the opt-in below) |
| `MCODE_ALLOW_ENDPOINT_OVERRIDE` | `1` enables the two endpoint overrides |
| `MCODE_MIRROR_CLI` | `0` disables the CLI-store mirror |

The endpoint overrides are opt-in on purpose: the account token endpoint
receives the refresh token and the PKCE verifier, and the API endpoint carries
the access token in every request. Without `MCODE_ALLOW_ENDPOINT_OVERRIDE=1`
both are ignored, and an override must be `https` (plaintext `http` is allowed
for loopback only).

## Provider configuration

The extension owns the whole provider: `baseUrl`, `api`, `authHeader`, the
**model catalog** and the OAuth flow. **`models.json` needs no `mcode` entry
at all** — the provider is self-contained, like `pi-meta-oauth` and the
built-in OAuth providers (zenmux, minimax).

The catalog lives in code on purpose: pi-web's Models panel rewrites
`~/.pi/agent/models.json` from its own runtime, and a provider whose models
only lived there lost its entire definition the first time that panel was
saved (the provider stayed, its models did not — and every model switch then
failed with "Model not found").

If an `mcode` entry does exist in `models.json`, the extension wins for
models, baseUrl and api. Do not add an `apiKey` there: the provider is
OAuth-only, and an `apiKey` would turn `/login mcode` into an auth-type menu.

## Commands

- `/login mcode` — pick a region, then reuse an existing mcode CLI session or
  sign in with a device code.
- `/mcode-status` — region, endpoint, token expiry, mirror path.
