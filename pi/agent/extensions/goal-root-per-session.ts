/**
 * goal-root-per-session — give pi-goal-x an isolated goal pool per pi session.
 *
 * Sets PI_GOAL_ROOT to ~/.pi/agent/goal-pools/<session-id> before goal-x
 * resolves its storage root. goal-x reads PI_GOAL_ROOT lazily and pins the
 * result per session (goal-root.ts configuredGoalRoot), so this handler MUST
 * be registered before goal-x's session_start handler runs. It is listed first
 * in settings.json "packages" so it loads (and registers) before pi-goal-x.
 *
 * session_start covers startup/resume/fork; before_agent_start re-applies in
 * case the session id changes in-process (e.g. /new, /cd) before goal-x
 * re-pins on the new id.
 *
 * Effect: each pi session gets its own goal ledger, locks, and focus —
 * parallel sessions in one project can no longer see or fight over goals.
 */
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const BASE = join(homedir(), ".pi", "agent", "goal-pools");

function applySessionGoalRoot(ctx: ExtensionContext): void {
	try {
		const sid = ctx.sessionManager.getSessionId();
		if (!sid) return; // no session / id not assigned: leave env untouched
		process.env.PI_GOAL_ROOT = join(BASE, sid);
	} catch {
		// never break the run over goal-root scoping
	}
}

export default function (pi: ExtensionAPI): void {
	pi.on("session_start", (_event, ctx) => applySessionGoalRoot(ctx));
	pi.on("before_agent_start", (_event, ctx) => applySessionGoalRoot(ctx));
}
