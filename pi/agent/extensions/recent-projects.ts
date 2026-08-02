/**
 * /recent-projects — Pick a recently opened project and switch pi's working
 * directory to it.
 *
 * Reads pi session directories under ~/.pi/agent/sessions/, decodes them back
 * to filesystem paths, sorts by most recent activity, and lets the user pick
 * one. On pick, switches pi's working directory to the selected project using
 * the same mechanism as pi-telegram-plus's /cd command: create a fresh session
 * scoped to the target directory, then switch the runtime to it.
 */
import { readdir, stat } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { SessionManager } from "@earendil-works/pi-coding-agent";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const SESSIONS_DIR = join(homedir(), ".pi", "agent", "sessions");

/** Decode a session dir name like "--home-user-Projects-foo--" into "/home/user/Projects/foo". */
function decodeProjectDir(name: string): string | null {
  if (!name.startsWith("--") || !name.endsWith("--")) return null;
  const encoded = name.slice(2, -2);
  if (!encoded) return null;
  return "/" + encoded.replace(/-/g, "/");
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("recent-projects", {
    description: "Pick a recently opened project and switch pi's working directory to it",
    handler: async (_args, ctx) => {
      const ui = ctx.ui;

      let entries;
      try {
        entries = await readdir(SESSIONS_DIR);
      } catch {
        ui.notify(`Cannot read ${SESSIONS_DIR}`, "error");
        return;
      }

      // Decode + stat, sorted by most recently modified
      const projects = (
        await Promise.all(
          entries.map(async (entry) => {
            const path = decodeProjectDir(entry);
            if (!path) return null;
            const mtime = (await stat(join(SESSIONS_DIR, entry))).mtimeMs;
            return { path, mtime };
          }),
        )
      )
        .filter((p): p is { path: string; mtime: number } => p !== null)
        .sort((a, b) => b.mtime - a.mtime);

      if (projects.length === 0) {
        ui.notify("No recent projects found", "info");
        return;
      }

      const labels = projects.map((p) => p.path.replace(homedir(), "~"));
      const choice = await ui.select("Recent projects:", labels);
      if (!choice) return;

      const targetCwd = projects[labels.indexOf(choice)].path;
      const info = await stat(targetCwd).catch(() => undefined);
      if (!info?.isDirectory()) {
        ui.notify(`Not a directory: ${targetCwd}`, "error");
        return;
      }

      // Same switch-cwd mechanism as pi-telegram-plus's /cd: create a fresh
      // session scoped to the target directory, then switch the runtime to it.
      const currentSessionFile = ctx.sessionManager.getSessionFile();
      const sessionManager = SessionManager.create(targetCwd, undefined, {
        ...(currentSessionFile ? { parentSession: currentSessionFile } : {}),
      });
      // Ensure the header-only session file exists before switchSession opens it.
      (sessionManager as unknown as { _rewriteFile?: () => void })._rewriteFile?.();
      const sessionPath = sessionManager.getSessionFile();
      if (!sessionPath) {
        ui.notify("Cannot switch cwd from an ephemeral session.", "error");
        return;
      }

      const result = await ctx.switchSession(sessionPath, {
        withSession: async (nextCtx) => {
          nextCtx.ui.notify(`✅ Switched to ${targetCwd}`, "info");
        },
      });
      if (result.cancelled) ui.notify("Cwd switch cancelled.", "info");
    },
  });
}
