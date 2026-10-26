/**
 * The mcode model catalog.
 *
 * The extension owns these definitions on purpose: pi-web's Models panel
 * rewrites ~/.pi/agent/models.json from its own runtime, and a provider whose
 * models only lived there lost its whole definition the first time the panel
 * was saved (the provider stayed, its models did not). Keeping the catalog in
 * code makes the provider self-contained: it always has its models, even
 * before the first login.
 */
import type { ProviderModelConfig } from "@earendil-works/pi-coding-agent";

export const MCODE_MODELS: ProviderModelConfig[] = [
	{
		id: "MiniMax-M3.1-Flash",
		name: "MiniMax M3.1 Flash (mcode plan)",
		reasoning: true,
		input: ["text", "image"],
		contextWindow: 512000,
		maxTokens: 128000,
		// The mcode plan bills both models the same; the flash model was
		// listed without rates in models.json, which pi treats as zero.
		cost: {
			input: 0.3,
			output: 1.2,
			cacheRead: 0.06,
			cacheWrite: 0,
		},
	},
	{
		id: "MiniMax-M3",
		name: "MiniMax M3 (mcode plan)",
		reasoning: true,
		input: ["text", "image"],
		contextWindow: 1000000,
		maxTokens: 128000,
		cost: {
			input: 0.3,
			output: 1.2,
			cacheRead: 0.06,
			cacheWrite: 0,
		},
	},
];
