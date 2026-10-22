#!/usr/bin/env node
// Prints the current MiniMax Code (mcode) OAuth access token.
// Used by ~/.pi/agent/models.json (provider "mcode"):
//   "apiKey": "!node ~/.pi/agent/mcode-token.mjs"
// Runs at request time, so it always picks up the token mcode last refreshed.
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const dir = path.join(os.homedir(), ".minimax", "auth");

function list(d) {
  try {
    return fs.readdirSync(d);
  } catch {
    return [];
  }
}

const records = [];
for (const env of list(dir)) {
  for (const region of list(path.join(dir, env))) {
    const file = path.join(dir, env, region, "mcode-public", "auth.json");
    try {
      const data = JSON.parse(fs.readFileSync(file, "utf8"));
      for (const rec of Object.values(data.records ?? {})) {
        if (rec.accessToken) records.push(rec);
      }
    } catch {
      // no store in this scope
    }
  }
}

records.sort((a, b) => (b.expiresAtMs ?? 0) - (a.expiresAtMs ?? 0));

if (records.length === 0) {
  console.error("mcode-token: no login token found — run `mcode login` (or open MiniMax Code) first");
  process.exit(1);
}

const newest = records[0];
if (newest.expiresAtMs && Date.now() > newest.expiresAtMs) {
  console.error(
    `mcode-token: token expired ${new Date(newest.expiresAtMs).toISOString()} — ` +
      "run `mcode` (or open the MiniMax Code app) once to refresh it",
  );
}

process.stdout.write(newest.accessToken);
