---
name: llama-benchmark
description: >
  Benchmark and tune llama-server / llama.cpp for maximum speed (tokens/sec, TTFT, throughput).
  Use this whenever the user mentions llama.cpp, llama-server, llama-bench, GGUF inference speed,
  tokens per second, tok/s, latency, throughput, "my model is slow", "how do I make inference
  faster", GPU offload, flash attention, KV cache quantization, context size tuning, batch size,
  speculative decoding, --parallel / concurrency serving, or picking parameters for a local LLM
  server. Also use when the user wants a reproducible before/after benchmark, a parameter sweep,
  or an optimized launch command for a given GPU/CPU. Trigger even if they only say things like
  "why is my local model only doing 8 tok/s" without naming llama.cpp explicitly.
license: MIT
metadata:
  version: 0.1.0
  category: performance
  tags: [llama.cpp, llama-server, benchmarking, inference, gpu, quantization]
---

# Llama Benchmark

Tune `llama-server` (and `llama.cpp` generally) for speed using measured evidence instead of
guesswork. The whole point is to replace "try random flags" with a short, reproducible loop:
**measure a baseline → change one thing → measure again → keep the winner → emit the launch
command.**

Token generation in llama.cpp is memory-bandwidth-bound, not compute-bound, so most speed comes
from a handful of decisions (which backend, how many layers on GPU, how big the KV cache is) and
very little from micro-tweaks. The skill is organized around that reality.

## When to use this

- "My local model is slow / only N tok/s" → diagnose + fix
- "What flags should I run llama-server with on my <GPU>?" → produce an optimized launch command
- "Compare these settings for me" → run a sweep and report
- "Benchmark this server" → drive `llama-bench` or hit a running server's API
- Picking quantization, context size, KV cache type, batch size, `--parallel` slot count

## Core principle: measure, don't guess

Numbers from the internet are a starting hypothesis, not the answer. What helps on an RTX 4090 may
do nothing on an RTX 3060. Always:

1. Establish a **baseline** on the actual machine (before touching flags).
2. Change **one variable at a time**, re-measure.
3. Repeat each measurement (`-r 3`) and report **mean ± spread** — single runs are noise.
4. Keep the winner, then move to the next variable.

Two number shapes to never confuse:
- **pp (prompt processing / prefill)** — how fast the prompt is ingested. Dominates TTFT and
  long-document/RAG workloads. Scales with batch size.
- **tg (token generation / decode)** — how fast tokens stream out. This is what users *feel* in
  chat. Mostly fixed by the model + backend + offload, and hurt by oversized context.

If tg is fine but pp is slow, tune batch size. If tg itself is slow, the problem is almost always
offload / backend / VRAM pressure — go to troubleshooting.

## The workflow

### Step 0 — Detect the environment (never skip)

Run these first; they change every recommendation:

```bash
# Which binary, and with which backend was it compiled?
llama-bench --version 2>/dev/null || ./build/bin/llama-bench --version
# Look for the backend lines: GGML_USE_CUDA=1 / GGML_USE_HIP / Metal / BLAS=0 (CPU-only)

# What GPU(s) and how much VRAM?
nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv   # NVIDIA
rocm-smi --showmeminfo vram                                         # AMD
system_profiler SPDisplaysDataType | grep -i 'Chipset\|VRAM'        # macOS

# CPU physical cores (NOT hyperthreads) for -t
lscpu | grep -E '^CPU\(s\)|Core\(s\) per socket|Model name'         # Linux
sysctl -n hw.physicalcpu hw.memsize                                 # macOS
```

Record: backend (CUDA/ROCm/Metal/CPU), VRAM, physical core count, model file + quantization.
A CPU-only build is roughly **10× slower** than a CUDA build on the same box — fix the build
before tuning any flag.

### Step 1 — Baseline with llama-bench

`llama-bench` gives clean, reproducible pp/tg without conversation noise. Start at a *short*
context so you isolate raw model speed:

```bash
llama-bench -m model.gguf -ngl 99 -fa 1 -p 512 -n 128 -r 3
```

Read the `pp512` and `tg128` columns. Convert to "is this normal?" using the reference table in
`references/findings.md` — if tg is >30% below the expected range for the GPU+model class, treat
it as a configuration problem, not a hardware limit.

### Step 2 — Sweep the high-impact variables (in order)

Only these move the needle meaningfully. Sweep top-to-bottom; stop improving when a step stops
helping.

| Order | Variable | Flag | Effect | Reference |
|---|---|---|---|---|
| 1 | Backend/build | (compile) | up to 10× | `references/optimization.md` |
| 2 | GPU offload | `-ngl` | non-linear cliff | `references/optimization.md` |
| 3 | Flash attention | `-fa 1` | frees KV VRAM, faster long-ctx | `references/optimization.md` |
| 4 | KV cache type | `-ctk`/`-ctv` | halves KV VRAM — **must match K & V** | `references/findings.md` |
| 5 | Context size | `-c` | direct VRAM tax on speed | `references/findings.md` |
| 6 | Batch sizes | `-b`/`-ub` | prefill speed only | `references/optimization.md` |
| 7 | Threads | `-t` | CPU / prefill only | `references/optimization.md` |
| 8 | Speculative decoding | `-md`, `--draft-max`, `--spec-type` | 1.5–2.5× (dense only) | `references/findings.md` |
| 9 | Concurrency | `--parallel` | multi-user throughput | `references/optimization.md` |

Use the bundled sweep script so the runs and the report are consistent:

```bash
python scripts/sweep.py \
  --bin llama-bench --model model.gguf \
  --base "-ngl 99 -fa 1" \
  --sweep "-c=4096,8192,16384,32768" \
  --sweep "-ctk=q8_0,q4_0 -ctv=q8_0,q4_0" \
  --p 512 --n 128 --reps 3 \
  --out bench-out/
```

It writes `bench-out/results.json` and `bench-out/report.md` (a sorted table of every config,
pp/tg with mean, and the best config called out). Add `--dry-run` to print the commands without
executing — useful to review the plan first.

### Step 3 — Verify the winning combination

Re-run the single best config a few times to confirm it's stable, then sanity-check quality
(a quantized KV cache or an aggressive quant can silently degrade output — spot-check a real
prompt). Don't ship a config whose speed win came from a quality regression.

### Step 4 — Benchmark the live server (if the goal is serving)

`llama-bench` measures the engine; it doesn't measure your HTTP serving path (queueing, slots,
TTFT). For a running server:

```bash
python scripts/serve_bench.py \
  --url http://127.0.0.1:8080 \
  --prompt-tokens 512 --max-tokens 128 \
  --concurrency 1,4,8 --reps 3
```

Reports TTFT, per-request tok/s, and aggregate tok/s per concurrency level. Watch for aggregate
throughput that stops rising as concurrency grows — that's when to tune `--parallel` or move to
vLLM (see `references/optimization.md` → multi-user).

### Step 5 — Emit the deliverable

Produce a short report:
1. Environment (backend, GPU, VRAM, model).
2. Baseline numbers.
3. Each variable tried and its measured effect (pp/tg delta).
4. **The final `llama-server` command**, assembled from the winners.
5. Any quality caveats.

Then hand over the exact launch command. Store results under `bench-out/` (JSON + markdown) so
runs are comparable across iterations.

## Fast path (when the user just wants a good command)

If they only want "give me the best flags", still run Step 0 and a one-line baseline, then start
from the hardware preset closest to their machine in `references/optimization.md` → "Presets by
hardware tier" and adjust `-c` to their real need. Always keep `-ngl 99 -fa 1` and matched KV
cache types unless the sweep says otherwise.

## Golden rules (the expensive mistakes)

These are the findings that account for the biggest, most surprising speed losses. Full detail
with numbers in `references/findings.md`.

- **Never mix KV cache types.** `-ctk q8_0 -ctv q4_0` costs ~40% throughput vs matching types.
  If you quantize the cache, quantize both sides the same (`q8_0/q8_0` or `q4_0/q4_0`).
- **`-ngl` partial offload is non-linear.** 10% of layers on CPU can cost 40–50% of total
  throughput. Fit the whole model, or shrink the model/context until you can.
- **`-c` is allocated up front.** Setting 128K "just in case" reserves ~16 GB of KV cache and
  starves the GPU of room for layers. Allocate what you need.
- **Match the build to the hardware first.** A CPU-only binary silently runs the "GPU" job on CPU.
- **Speculative decoding is not universal.** Great for dense models with a same-family draft; can
  *slow down* MoE models and low-acceptance workloads. Measure it.
- **Sampling params (temp/top-p/min-p) never affect tok/s.** Don't tune them for speed.
- **Run one configuration at a time.** Two servers side by side benchmark contention, not the model.

## Reference files

Read the one you need — don't load them all.

- `references/optimization.md` — full flag-by-flag guide, presets per hardware tier, multi-GPU and
  multi-user patterns, Ollama equivalents.
- `references/findings.md` — distilled measurements: reference tok/s by GPU, KV-type penalty,
  context-depth throughput decay, speculative decoding, backend sampling. Contains a table of
  contents.
- `references/troubleshooting.md` — symptom → likely cause → fix (fast-but-then-slow, low GPU
  util, partial offload, Ollama-slower-than-bare, spec-decoding regressions).

## Bundled scripts

- `scripts/sweep.py` — cartesian sweep over llama-bench flags → `results.json` + `report.md`.
  Stdlib only. `--dry-run` prints commands.
- `scripts/serve_bench.py` — benchmarks a live llama-server over its OpenAI-compatible HTTP API
  (TTFT, per-request and aggregate tok/s across concurrency levels). Stdlib only.

Both scripts print a clear error if the binary/server isn't reachable rather than failing silently.
