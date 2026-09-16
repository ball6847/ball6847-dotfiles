# Benchmark Findings — distilled measurements

Evidence behind the recommendations. Use these to sanity-check your own numbers and to know
"what should this machine do?".

## Table of contents

1. [Reference throughput by GPU/model](#1-reference-throughput)
2. [The build/backend gap](#2-buildbackend-gap)
3. [Partial offload cliff](#3-partial-offload-cliff)
4. [KV cache type: never mix K and V](#4-kv-cache-type-never-mix)
5. [Context-depth throughput decay](#5-context-depth-decay)
6. [Context size vs token speed (KV VRAM tax)](#6-context-size-vs-speed)
7. [Flag-combination deltas (RTX 4070, 8B)](#7-flag-combination-deltas)
8. [Speculative decoding: win vs loss](#8-speculative-decoding)
9. [Backend sampling `-bs`](#9-backend-sampling)
10. [Prefill vs batch size](#10-prefill-vs-batch-size)
11. [Measurement methodology](#11-methodology)

---

## 1. Reference throughput

Expected `tg` (token generation) ranges — "low" is relative, so use this as the baseline before
declaring a problem:

| GPU | 7B Q4_K_M | 13B Q4_K_M | 70B Q4_K_M |
|---|---|---|---|
| RTX 4060 8GB | 38–52 | ✗ | ✗ |
| RTX 3070 8GB | 50–62 | ✗ | ✗ |
| RTX 4070 12GB | 55–70 | 25–35 | ✗ |
| RTX 4090 24GB | 85–110 | 45–60 | ✗ |
| RTX 3090 24GB | 70–90 | 38–52 | ✗ |
| RX 7900 XTX 24GB | 65–85 | 35–48 | ✗ |
| Apple M4 Pro 24GB | 45–60 | 25–35 | ✗ (48GB) |
| CPU-only (Ryzen 9 DDR5) | 12–20 | 6–10 | ✗ |

Generation is memory-bandwidth-bound: an RTX 3070 (448 GB/s) often beats an RTX 4060 Ti
(288 GB/s). If you're >30% below range, suspect thermal throttling, single-channel RAM, or a
PCIe/offload bottleneck — not the flags.

## 2. Build/backend gap

Same hardware, Llama 3.1 8B Q4_K_M, tg128:

| Build | tg128 (t/s) | pp512 (t/s) |
|---|---|---|
| CUDA build | 63.4 | 1812 |
| CPU-only build | 9.8 | 156 |

≈ **−85%** just from the build. This is why "check the backend" is Step 0.

## 3. Partial offload cliff

7B Q4_K_M on RTX 4070:

| Layers on GPU | tg128 (t/s) | vs full |
|---|---|---|
| all (99) | ~63–80 | — |
| ~70% (`-ngl 24`) | 38.2 | **−40%** |
| 0 (CPU) | 9.8 | −85% |

Losing ~30% of layers costs ~40% of throughput — non-linear because CPU layers serialize every
token.

## 4. KV cache type: never mix

MiniMax-M2.5 Q8_0 (M3 Ultra), llama-bench:

| Keys | Values | Prompt tok/s | Generation tok/s | Penalty |
|---|---|---|---|---|
| q8_0 | q8_0 | 562 | 37.4 | — |
| q4_0 | q4_0 | 561 | 37.2 | ~0% |
| q8_0 | q4_0 | 289 | 22.3 | **−40%** |
| q4_0 | q8_0 | 286 | 22.3 | **−40%** |

Matching types perform identically regardless of q8_0 vs q4_0; mixing forces a slow conversion
path on every cache access. **Rule: match K and V.** (If you want q4_0 savings, use q4_0 for both.)

Also: a compressed/"turbo" KV path is not automatically faster. On an M4 Pro, plain `f16` KV stayed
faster than `turbo3` at moderate prompt sizes while turbo used less memory — the tradeoff only pays
off at long context. Test rather than assume.

## 5. Context-depth decay

Combined throughput (prefill + decode) vs context depth, MiniMax-M2.5 on M3 Ultra:

| Context depth | Throughput (tok/s) | vs 4K |
|---|---|---|
| 4,096 | 335 | — |
| 8,192 | 345 | +3% |
| 16,384 | 291 | −13% |
| 32,768 | 207 | −38% |
| 65,536 | 128 | −62% |
| 131,072 | 69 | −79% |

Requests get slower as context grows because each new turn re-processes the conversation. This is
why allocates-context-up-front (`-c`) and KV quantization matter so much for long-context workloads.

## 6. Context size vs speed

Qwen3 8B Q4_K_M on RTX 4090, KV cache FP16:

| `-c` | KV cache | Total VRAM | Token speed |
|---|---|---|---|
| 2,048 | ~0.25 GB | ~5.9 GB | ~105 t/s |
| 4,096 | ~0.5 GB | ~6.2 GB | ~103 t/s |
| 8,192 | ~1.0 GB | ~6.7 GB | ~98 t/s |
| 16,384 | ~2.0 GB | ~7.7 GB | ~85 t/s |
| 32,768 | ~4.0 GB | ~9.7 GB | ~68 t/s |
| 131,072 | ~16.0 GB | ~21.7 GB | ~25 t/s |

128K context = ~1/4 the speed of 4K, and eats most of a 24 GB card. Allocate what you need.

## 7. Flag-combination deltas

Llama 3.1 8B Q4_K_M, RTX 4070, llama-bench tg128, 3 runs averaged:

| Configuration | tg128 | pp512 | Note |
|---|---|---|---|
| Baseline `-ngl 99 -c 2048` | 63.4 | 1812 | start |
| + `-fa 1` | 65.1 | 1834 | small at short ctx; matters at long |
| + `-c 16384` (no FA) | 61.2 | 1789 | context cost |
| + `-c 16384` + `-fa` | 64.8 | 1821 | FA recovers it |
| + `-ctk q8_0 -ctv q8_0` | 65.3 | 1843 | small win + VRAM freed |
| + `-b 4096` | 65.1 | 2187 | **+20% prefill**, no tg change |
| All combined | 65.5 | 2201 | +3% tg, +21% pp |
| Partial offload `-ngl 24` | 38.2 | 821 | −40% tg |
| CPU-only build | 9.8 | 156 | −85% |

Takeaway: on a GPU already running fully offloaded, individual flags give modest **tg** gains
(3–4% total) but meaningful **pp** gains (batch size). The flags matter *most* for fitting context
in limited VRAM and for prefill-heavy workloads.

## 8. Speculative decoding

- Dense win: Llama 3.3 70B target + Llama 3.2 1B draft on RTX 3090 → ~30 → >160 t/s.
- MoE loss: Qwen3.6-35B-A3B (3B active) on RTX 3090 → **no** config net-speedup; −3% to −12%
  across configurations (expert switching overhead).
- Ngram (no draft model): +10–40% on repetitive/structured output, zero extra VRAM.

Verdict: measure per workload. Great for dense models with a same-family draft and predictable
output (code, structured text); risky for MoE and open-ended chat.

## 9. Backend sampling

`-bs` / `--backend-sampling`, Qwen2.5-7B F16 on RTX 5090, CUDA:

| Config | 1 slot tok/s | 32 slots tok/s | 32-slot TPOT |
|---|---|---|---|
| Default | 100.1 | 705.9 | 41.2 ms |
| `-bs` | 101.4 | **1045.8** | 25.4 ms |
| vLLM BF16 (reference) | 92.9 | 1404.7 | 17.7 ms |

+48% at 32 slots, single-slot unchanged, greedy output byte-identical. A concurrency-scaling win.

## 10. Prefill vs batch size

Prompt processing speed falls as prompts grow; bigger `-b` recovers it:

| Prompt tokens | Speed (tok/s) |
|---|---|
| 512 | 562 |
| 2,048 | 528 |
| 8,192 | 416 |

And going `-b 512` → `-b 4096` lifted pp16384 ~35–40% on a 4090. Batch size is a **prefill** lever.

## 11. Methodology

So your numbers mean something:

- Run **one server at a time**. Side-by-side servers measure contention, not the model.
- Use `llama-bench` for the engine (clean, repeatable); use the server API for the serving path.
- Repeat: `-r 3` minimum, report mean ± spread.
- Fix test inputs: same prompt length (`-p`), same generation length (`-n`), same model/quant.
- For server benches: fixed prompt + output length, disable prefix cache (`--cache-ram 0`) so every
  request does a real prefill, and send token arrays if comparing engines.
- Change one variable at a time; keep the winner before moving on.
- Watch for thermal throttling and background load on long sweeps.
