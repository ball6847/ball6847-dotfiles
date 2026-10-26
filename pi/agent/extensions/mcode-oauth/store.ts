/**
 * Mirror for the mcode CLI credential store (~/.minimax/auth/...).
 *
 * pi keeps its own copy of the credential in its credential store; this module
 * writes the CLI-native record shape so that
 *   - the `mcode` CLI stays logged in, and
 *   - ~/.pi/agent/mcode-token.mjs keeps printing a fresh access token.
 *
 * Writes are atomic (temp file + rename) and private (0600 files, 0700 dirs).
 */
import { createHash, randomUUID } from "node:crypto";
import { chmod, mkdir, open, readFile, rename, unlink } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { BUILD_ENV, MCODE_AUDIENCE, MCODE_CLIENT_ID, type McodeRegion } from "./constants.ts";
import type { McodeGrant } from "./oauth.ts";

export interface CliCredential {
	accessToken: string;
	refreshToken: string;
	expiresAtMs: number;
	scopes: string[];
	generation: number;
}

interface CliRecord {
	schemaVersion: number;
	accessToken?: string;
	refreshToken?: string;
	tokenType?: string;
	clientId?: string;
	scopes?: string[];
	audience?: string;
	expiresAtMs?: number;
	generation?: number;
	loginEpoch?: string;
	subject?: string;
	accountId?: string;
}

interface CliStore {
	schemaVersion: number;
	records: Record<string, CliRecord>;
}

export interface CliNamespace {
	authHome: string;
	namespaceHome: string;
	credentialPath: string;
	statePath: string;
	lockPath: string;
	recordKey: string;
}

/** Mirrors the CLI's data-dir resolution (MINIMAX_DATA_DIR / MAVIS_DATA_DIR). */
export function resolveDataDir(): string {
	const override = process.env.MINIMAX_DATA_DIR?.trim() || process.env.MAVIS_DATA_DIR?.trim();
	if (override) return resolve(override);
	return join(homedir(), ".minimax");
}

/** Same namespace layout and record key the mcode CLI uses. */
export function cliNamespace(region: McodeRegion, dataDir = resolveDataDir()): CliNamespace {
	const authHome = join(resolve(dataDir), "auth");
	const namespaceHome = join(authHome, BUILD_ENV, region, MCODE_CLIENT_ID);
	const service = `com.minimax.mcode.oauth.${BUILD_ENV}.${region}`;
	const account = createHash("sha256")
		.update(`${authHome}\0${MCODE_CLIENT_ID}`)
		.digest("base64url");
	return {
		authHome,
		namespaceHome,
		credentialPath: join(namespaceHome, "auth.json"),
		statePath: join(namespaceHome, "auth-state.json"),
		lockPath: join(namespaceHome, "pi-extension.lock"),
		recordKey: `${service}\0${account}`,
	};
}

async function readStore(credentialPath: string): Promise<CliStore> {
	try {
		const raw = await readFile(credentialPath, "utf8");
		const parsed = JSON.parse(raw);
		if (parsed?.schemaVersion === 1 && parsed.records && typeof parsed.records === "object") {
			return parsed as CliStore;
		}
	} catch {
		// fresh store
	}
	return { schemaVersion: 1, records: {} };
}

/** Newest credential in the CLI store for one region, if any. */
export async function readCliCredential(
	region: McodeRegion,
	dataDir = resolveDataDir(),
): Promise<CliCredential | undefined> {
	const namespace = cliNamespace(region, dataDir);
	let store: CliStore;
	try {
		store = await readStore(namespace.credentialPath);
	} catch {
		return undefined;
	}
	const records = Object.values(store.records).filter(
		(record) => typeof record.accessToken === "string" && record.accessToken.length > 0,
	);
	if (records.length === 0) return undefined;
	records.sort((a, b) => (b.expiresAtMs ?? 0) - (a.expiresAtMs ?? 0));
	const newest = records[0] as CliRecord;
	return {
		accessToken: newest.accessToken as string,
		refreshToken: typeof newest.refreshToken === "string" ? newest.refreshToken : "",
		expiresAtMs: newest.expiresAtMs ?? 0,
		scopes: Array.isArray(newest.scopes) ? newest.scopes : [],
		generation: newest.generation ?? 0,
	};
}

async function atomicWritePrivateFile(path: string, content: string): Promise<void> {
	const directory = dirname(path);
	await mkdir(directory, { recursive: true, mode: 0o700 });
	if (process.platform !== "win32") await chmod(directory, 0o700);
	const temporaryPath = `${path}.${process.pid}.${Date.now()}.tmp`;
	const handle = await open(temporaryPath, "wx", 0o600);
	try {
		await handle.writeFile(content, { encoding: "utf8" });
		await handle.sync();
	} finally {
		await handle.close();
	}
	try {
		if (process.platform !== "win32") await chmod(temporaryPath, 0o600);
		await rename(temporaryPath, path);
	} catch (error) {
		await unlink(temporaryPath).catch(() => undefined);
		throw error;
	}
}

/** Simple exclusive lock so we do not clobber a concurrent CLI write. */
async function withLock<T>(lockPath: string, fn: () => Promise<T>): Promise<T> {
	await mkdir(dirname(lockPath), { recursive: true, mode: 0o700 });
	const deadline = Date.now() + 5_000;
	for (;;) {
		try {
			const handle = await open(lockPath, "wx", 0o600);
			await handle.close();
			break;
		} catch (error) {
			const code = (error as NodeJS.ErrnoException).code;
			if (code !== "EEXIST" || Date.now() > deadline) {
				// Give up on the lock rather than blocking the login flow.
				break;
			}
			await new Promise((resolve) => setTimeout(resolve, 150));
		}
	}
	try {
		return await fn();
	} finally {
		await unlink(lockPath).catch(() => undefined);
	}
}

/**
 * Write the grant into the CLI store, merging with whatever is already there
 * so other providers/regions keep their records.
 */
export async function saveToCliStore(
	grant: McodeGrant,
	region: McodeRegion,
	dataDir = resolveDataDir(),
): Promise<CliNamespace> {
	const namespace = cliNamespace(region, dataDir);
	await withLock(namespace.lockPath, async () => {
		const store = await readStore(namespace.credentialPath);

		let generation = 0;
		try {
			const state = JSON.parse(await readFile(namespace.statePath, "utf8"));
			const value = state?.generation;
			if (Number.isSafeInteger(value)) generation = Math.max(generation, value as number);
		} catch {
			// no prior state
		}
		const prior = store.records[namespace.recordKey];
		const priorGeneration = prior?.generation;
		if (Number.isSafeInteger(priorGeneration)) {
			generation = Math.max(generation, priorGeneration as number);
		}
		generation += 1;

		const record: CliRecord = {
			schemaVersion: 1,
			accessToken: grant.accessToken,
			refreshToken: grant.refreshToken,
			tokenType: "Bearer",
			clientId: MCODE_CLIENT_ID,
			scopes: grant.scopes,
			audience: MCODE_AUDIENCE,
			expiresAtMs: grant.expiresAtMs,
			generation,
			loginEpoch: randomUUID(),
		};
		if (grant.subject) record.subject = grant.subject;
		if (grant.accountId) record.accountId = grant.accountId;

		store.records[namespace.recordKey] = record;
		await atomicWritePrivateFile(
			namespace.credentialPath,
			`${JSON.stringify(store, null, 2)}\n`,
		);

		const state = {
			schemaVersion: 2,
			status: "authenticated",
			storeKind: "file",
			clientId: MCODE_CLIENT_ID,
			scopes: grant.scopes,
			audience: MCODE_AUDIENCE,
			buildEnv: BUILD_ENV,
			region,
			expiresAtMs: grant.expiresAtMs,
			generation,
		};
		await atomicWritePrivateFile(namespace.statePath, `${JSON.stringify(state, null, 2)}\n`);
	});
	return namespace;
}
