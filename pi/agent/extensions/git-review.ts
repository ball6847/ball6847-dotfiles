/**
 * /git-review — Review staged git changes.
 *
 * Runs `git diff --cached` (or unstaged diff if nothing is staged), embeds the
 * output into the prompt, and asks the agent to review it.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerCommand("git-review", {
    description: "Review staged git changes (falls back to unstaged diff)",
    handler: async (_args, ctx) => {
      const { stdout, code } = await pi.exec("git", ["diff", "--cached"], {
        cwd: ctx.cwd,
      });

      let diff = stdout;
      if (code !== 0) {
        ctx.ui.notify("Failed to run git diff --cached", "error");
        return;
      }

      // Nothing staged → fall back to unstaged diff
      if (!diff.trim()) {
        const unstaged = await pi.exec("git", ["diff"], { cwd: ctx.cwd });
        diff = unstaged.stdout;
        if (unstaged.code !== 0) {
          ctx.ui.notify("Failed to run git diff", "error");
          return;
        }
      }

      if (!diff.trim()) {
        ctx.ui.notify("No changes to review", "info");
        return;
      }

      const prompt = [
        "Review the following git diff. Focus on:",
        "- Bugs and logic errors",
        "- Security issues",
        "- Error handling gaps",
        "",
        "```diff",
        diff,
        "```",
      ].join("\n");

      await ctx.sendUserMessage(prompt);
    },
  });
}
