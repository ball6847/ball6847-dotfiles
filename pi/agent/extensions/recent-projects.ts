/**
 * /recent-projects — Pick a recently opened project and show its path.
 *
 * Reads pi session directories under ~/.pi/agent/sessions/, decodes them back
 * to filesystem paths, sorts by most recent activity, and lets the user pick
 * one. The chosen path is shown in a notification; the user copies it
 * themselves.
 */
import { readdir, stat } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
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
    description: "Pick a recently opened project and show its path",
    handler: async (_args, ctx) => {
      let entries;
      try {
        entries = await readdir(SESSIONS_DIR);
      } catch {
        ctx.ui.notify(`Cannot read ${SESSIONS_DIR}`, "error");
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
        ctx.ui.notify("No recent projects found", "info");
        return;
      }

      const labels = projects.map((p) => p.path.replace(homedir(), "~"));
      const choice = await ctx.ui.select("Recent projects:", labels);
      if (!choice) return;

      const selected = projects[labels.indexOf(choice)];
      ctx.ui.notify(selected.path, "info");
    },
  });
}
