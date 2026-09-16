# Optimization Reference — llama.cpp / llama-server

Flag-by-flag guide, hardware presets, and serving patterns. Read this when you need the *why* and
*how* behind a parameter, or when assembling a launch command.

## Table of contents

1. [Build/backend: fix this first](#1-buildbackend-fix-this-first)
2. [`-ngl` / `--n-gpu-layers` (GPU offload)](#2--ngl--n-gpu-layers)
3. [`-c` / `--ctx-size` (context)](#3--c--ctx-size)
4. [`-fa` / `--flash-attn`](#4--fa--flash-attn)
5. [KV cache quantization (`-ctk` / `-ctv`)](#5-kv-cache-quantization)
6. [Batch size (`-b` / `--batch-size`, `-ub` / `--ubatch-size`)](#6-batch-size)
7. [Threads (`-t`)](#7-threads)
8. [Memory loading (`--mmap` / `--no-mmap` / `--mlock`)](#8-memory-loading)
9. [Quantization format choice](#9-quantization-format-choice)
10. [Speculative decoding](#10-speculative-decoding)
11. [Multi-user serving (`--parallel`)](#11-multi-user-serving)
12. [Multi-GPU split modes](#12-multi-gpu-split-modes)
13. [Backend sampling (`-bs`)](#13-backend-sampling)
14. [Sampling params — NOT speed](#14-sampling-params--not-speed)
15. [Presets by hardware tier](#15-presets-by-hardware-tier)
16. [Ollama equivalents](#16-ollama-equivalents)

---

## 1. Build/backend: fix this first

A CPU-only build can be ~10× slower than a CUDA build on the same machine. Verify before touching
flags:

```bash
llama-bench --version            # look for GGML_USE_CUDA / GGML_USE_HIP / Metal
# "BLAS = 0" with no CUDA/HIP/Metal device line ⇒ CPU-only build
```

Build commands:

```bash
git clone https://github.com/ggml-org/llama.cpp && cd llama.cpp

# NVIDIA CUDA
cmake -B build -DGGML_CUDA=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j $(nproc)

# AMD ROCm (gfx1100 = RX 7900, gfx1030 = RX 6800/6900, gfx1200 = RX 9070)
cmake -B build -DGGML_HIP=ON -DAMDGPU_TARGETS="gfx1100" -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j $(nproc)

# Apple Silicon (Metal is on by default)
cmake -B build -DGGML_METAL=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j $(nproc)
```

Windows pre-built binaries: pick `...-win-cuda-cu12.x-x64.zip` (NVIDIA) or `...-win-rocm-x64.zip`
(AMD). The `-avx2`/`-avx512` variants are CPU-only and dramatically slower on any real GPU.

Keep llama.cpp current — builds land daily and Metal/CUDA/batching improve often. `brew upgrade
llama.cpp` before a benchmark run on macOS.

## 2. `-ngl` / `--n-gpu-layers`

The single most impactful flag. `-ngl 99` means "all layers" (llama.cpp clamps to the real layer
count). Always start at 99 and lower only on OOM.

Partial offload is **non-linear**: the CPU layers sit in the critical path of every token, and GPU
memory bandwidth is ~10× CPU's, so the GPU idles waiting on the CPU.

| Layers on GPU | Scenario | Approx t/s (7B Q4_K_M, RTX 4070) |
|---|---|---|
| 99 (all) | full GPU | ~70–80 |
| ~85% | near-full | ~50–60 |
| ~60% | significant CPU tail | ~25–35 |
| ~30% | mostly CPU | ~10–15 |
| 0 | pure CPU | ~8–12 |

Rule: a smaller model fully on GPU almost always beats a bigger model split across CPU+GPU.

## 3. `-c` / `--ctx-size`

KV cache VRAM ≈ `(ctx_tokens / 1024) × 0.5 GB` for a 7–8B model at FP16 — and it's **reserved up
front**, whether or not you use it. Every extra token costs VRAM that could hold GPU layers.

Practical guidance:
- Interactive chat: `-c 4096`–`8192`
- Document / RAG: `-c 16384`–`32768`
- Agent / long-context: `-c 65536`–`131072` (pair with flash attention + q8_0 KV)

Setting `-c` above the model's trained window degrades quality without giving useful context —
check the model card.

## 4. `-fa` / `--flash-attn`

Enable on essentially every CUDA/ROCm build (RTX 20-series and newer / compute capability 7.0+).
Benefits: reduces KV cache VRAM 20–50%, slightly faster attention at long context, and it is a
**prerequisite for KV cache quantization**. No quality downside. If an older model doesn't support
it, llama.cpp falls back automatically.

```bash
llama-bench -m model.gguf -ngl 99 -fa 1 -p 512,8192 -n 128 -r 3
```

## 5. KV cache quantization

`--cache-type-k` / `--cache-type-v` (short `-ctk`/`-ctv`) compress the attention cache from FP16.

| Type | VRAM vs f16 | Quality | Use |
|---|---|---|---|
| f16 | 100% | none | short context, VRAM headroom |
| q8_0 | ~50% | barely perceptible | default when VRAM is tight |
| q4_0 | ~25% | noticeable at long context | emergency for 64K+ |
| turbo3 (compressed/turbo path) | less than f16 | varies | test — sometimes slower than f16 at moderate prompts |

**Critical rule (measured): always match K and V types.** Mixing them costs ~40% throughput on both
prefill and generation (see `findings.md`). If memory forces you down, take `q4_0/q4_0` over
`q8_0/q4_0`.

Requires `-fa 1`.

## 6. Batch size

Two related flags:
- `-b` / `--batch-size`: logical batch cap for prefill.
- `-ub` / `--ubatch-size`: physical micro-batch the GPU runs. Must be `<= -b`. Larger uses more
  VRAM for compute buffers.

Batch size affects **prefill (pp), not decode (tg)**. For single-user chat with short prompts it
barely matters. For long documents/system prompts, `-b 4096` can lift `pp16384` ~35–40% vs `-b 512`
on a 4090. Defaults are typically `-b 2048 -ub 512`; on 24 GB+ cards try `-ub 1024`.

## 7. Threads

`-t` = CPU threads for non-GPU work (tokenization, sampling, CPU layers). Match **physical** core
count, not hyperthreads — SMT/HT contention cancels its own gains. On Intel 12th-gen+ hybrid CPUs,
prefer P-cores only; E-cores often hurt. On multi-CCD AMD, pin to one CCD with `taskset`.

```bash
taskset -c 0-15 llama-server -m model.gguf -ngl 99 -t 16 -fa
```

Sweep it, don't assume:

```bash
for t in 4 6 8 10 12 16; do
  llama-bench -m model.gguf -ngl 0 -t $t -p 0 -n 64 -r 2 | grep tg
done
```

## 8. Memory loading

- Default **mmap**: maps the file, fast load, OS may page it out.
- `--no-mmap`: load fully into RAM up front — stable inference, slower start, can OOM if RAM-tight.
- `--mlock`: pin pages in RAM so the OS can't evict them (needs `ulimit -l unlimited` on Linux).

Use `--no-mmap`/`--mlock` when the model lives on slow/network storage or you see erratic speed
spikes. If everything is on GPU, this matters little.

## 9. Quantization format choice

| Format | 7B size | GPU speed | CPU speed | Quality |
|---|---|---|---|---|
| Q2_K | ~2.7 GB | fastest | fast | severe — avoid |
| Q3_K_M | ~3.1 GB | very fast | fast | significant — last resort |
| IQ4_XS | ~4.3 GB | moderate | slower | very low (better than Q4_K_M) |
| **Q4_K_M** | ~4.6 GB | fast | good | low — **default pick** |
| Q5_K_M | ~5.3 GB | fast | good | very low |
| Q6_K | ~6.1 GB | slightly slower | slower | minimal |
| Q8_0 | ~8.5 GB | slower | slowest | near-zero |

I-quants use lookup tables during decode → extra CPU overhead; on GPU, plain K-quants (Q4_K_M)
usually win on tok/s. Use Q4_K_M for speed, IQ4_XS only if quality-constrained *and* VRAM-tight.

## 10. Speculative decoding

A small draft model proposes tokens; the target verifies them in one forward pass. 1.5–2.5×
speedup when acceptance is high, mathematically identical output. Requires a **same-family / same
vocab** draft.

```bash
llama-server -m target.gguf -md draft.gguf \
  -ngl 999 -ngld 999 -fa -c 4096 \
  --draft-max 5 --draft-min 1
```

No draft model? ngram speculation uses the existing context (zero extra VRAM, ~10–40% on
repetitive/structured output):

```bash
llama-server -m model.gguf -ngl 999 -fa --spec-type ngram-simple --draft-max 16
```

**Caveats:** hurts MoE models (expert switching overhead) and low-acceptance workloads. Always
measure; check the logged `draft acceptance rate`. If it regresses, drop `--draft-max` to 2–3 or
disable it.

## 11. Multi-user serving

`--parallel N` allocates N slots, each with its own KV cache, sharing GPU compute via continuous
batching.

**The classic mistake:** `--ctx-size` is the **total across all slots**, not per slot. With
`--parallel 4 --ctx-size 32768`, each user gets `32768/4 = 8192`.

| Concurrent users | `--parallel` | per-slot context |
|---|---|---|
| 1 | 1 | all of `-c` |
| 2 | 2 | half |
| 3–4 | 4 | quarter |
| 5–8 | 8 | eighth (stretching it) |
| 8–10+ | — | switch to vLLM |

Throughput does **not** scale linearly: 4 slots give roughly 1.3× single-slot aggregate throughput
but 4× the concurrency — the win is "no one waits", not "faster total".

Reference multi-user command (24 GB GPU, 4 slots):

```bash
llama-server -m model.gguf --host 127.0.0.1 --port 8080 \
  --parallel 4 --ctx-size 32768 \
  --n-gpu-layers 999 --batch-size 2048 --ubatch-size 512 \
  --threads 8 --cont-batching --metrics \
  --api-key file:/etc/llama-server/api-key.txt
```

Monitor with `--metrics` (`/metrics`): queue depth (`requests_deferred`), slot utilization, KV
cache fill. Sustained queue depth > 0 means add slots (if VRAM allows) or move to vLLM.

Don't expose the port directly — put HTTPS + rate limiting + auth (Caddy/nginx) in front, and for
streaming set `flush_interval -1` (Caddy) or `proxy_buffering off` (nginx).

## 12. Multi-GPU split modes

```bash
-sa / --split-mode layer   # default: sequential layer split (one GPU idle at a time)
-sa row                    # split weight matrices across GPUs (more balanced)
-sa graph                  # simultaneous GPU use (needs NCCL; ~3-4x vs layer split)
--tensor-split 6,4         # bias distribution for unequal VRAM (60% / 40%)
```

Layer split leaves GPUs taking turns; row/graph keep them busier. Graph split needs NCCL and a
build with NCCL support. For most single-GPU homelab setups this is irrelevant — only pursue it
when the model genuinely doesn't fit one card.

## 13. Backend sampling

`-bs` / `--backend-sampling` moves sampling onto the backend, removing a per-decode-step
device→host copy of the full logits matrix. In a 32-slot RTX 5090 test this lifted throughput
~700 → ~1046 tok/s (+48%) with single-slot unchanged and greedy output byte-identical. Experimental
and off by default; worth measuring if you serve many concurrent slots.

## 14. Sampling params — NOT speed

`--temp`, `--top-p`, `--top-k`, `--min-p`, `--repeat-penalty` run *after* the logits are computed.
They never change tok/s. Modern community default for quality:
`--temp 0.7 --min-p 0.05 --top-k 0 --top-p 1.0`. Don't tune these for speed.

## 15. Presets by hardware tier

Starting points — sweep to confirm on the actual machine.

**RTX 3060 12 GB — 7–8B Q4_K_M, chat**
```bash
llama-server -m model.gguf -ngl 99 -c 8192 -fa \
  --cache-type-k q8_0 --cache-type-v q8_0 \
  -t 8 -b 2048 -ub 512 --host 127.0.0.1 --port 8080
```
Expected ~40–55 t/s tg128.

**RTX 3090 / 4090 24 GB — 30B Q4_K_M, quality**
```bash
llama-server -m model.gguf -ngl 99 -c 16384 -fa -t 12 \
  -b 4096 -ub 512 --no-mmap --host 127.0.0.1 --port 8080
```
Expected ~30–45 t/s tg128.

**RTX 4070 Ti 16 GB — 13B Q4_K_M, balanced**
```bash
llama-server -m model.gguf -ngl 99 -c 16384 -fa \
  --cache-type-k q8_0 --cache-type-v q8_0 -t 10 -b 2048 -ub 512 \
  --host 127.0.0.1 --port 8080
```
Expected ~50–65 t/s tg128.

**RTX 5090 32 GB — 32B Q5_K_M, flagship**
```bash
llama-server -m model.gguf -ngl 99 -c 32768 -fa -t 12 -b 4096 -ub 1024 --no-mmap \
  --host 127.0.0.1 --port 8080
```
Expected ~55–80 t/s tg128. Add `-bs` for many-slot serving.

**AMD RX 7900 XTX 24 GB — 8B Q4_K_M (ROCm)**
```bash
llama-server -m model.gguf -ngl 99 -c 8192 -fa -t 10 -b 2048 -ub 512 \
  --host 127.0.0.1 --port 8080
```
Expected ~55–75 t/s tg128. KV quant support varies by ROCm build — test before relying on it.

**Apple Silicon (M3/M4 +) — unified memory**
```bash
llama-server -m model.gguf -ngl 999 -c 8192 -fa \
  --cache-type-k q8_0 --cache-type-v q8_0 --host 127.0.0.1 --port 8080
```
All system RAM is available to the GPU; no separate VRAM cap.

**CPU-only**
```bash
llama-server -m model.gguf -ngl 0 -fa -c 4096 -t <P-cores> --host 127.0.0.1 --port 8080
```

## 16. Ollama equivalents

Ollama wraps llama.cpp; map the flags to env vars:

| Env var | llama.cpp flag | Value |
|---|---|---|
| `OLLAMA_FLASH_ATTENTION` | `-fa` | `1` |
| `OLLAMA_KV_CACHE_TYPE` | `-ctk`/`-ctv` | `q8_0` |
| `OLLAMA_NUM_PARALLEL` | `--parallel` | `1` (single user) |
| `OLLAMA_MAX_LOADED_MODELS` | — | `1` |
| `OLLAMA_CONTEXT_LENGTH` | `-c` | e.g. `8192` |
| `OLLAMA_NUM_THREAD` | `-t` | physical cores |

Ollama adds ~5–15% API overhead vs bare llama.cpp. If you see 30%+, check FA, context, and
offload match. `ollama ps` shows which device the model landed on.
