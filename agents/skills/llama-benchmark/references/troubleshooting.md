# Troubleshooting — symptom → cause → fix

Start from the symptom the user reports. Diagnose before changing flags.

## Diagnostic commands

```bash
# What is the model actually doing? Read the startup log:
#   llm_load_tensors: offloaded 33/33 layers to GPU   ← good
#   llm_load_tensors: offloaded 12/33 layers to GPU   ← partial offload (bad)
#   llm_load_tensors: CUDA/Metal backend              ← good
#   llm_load_tensors: CPU backend                     ← bad if you have a GPU
#   kv_cache_init: CUDA0 KV buffer size = 4096.00 MiB ← 4 GB just for cache

# Live GPU utilization (should be 60–95% during generation):
watch -n 0.5 'nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader'   # NVIDIA
radeontop                                                                                             # AMD
# macOS: Activity Monitor → GPU History
```

If GPU utilization is <30% during generation, or spiky between 0 and 100%, something's wrong —
see below.

## "Loads fast but generates slowly"

**Almost always partial CPU offload.** mmap makes loading fast regardless of where inference runs.
Check the log for `offloaded X/Y`; if X < Y:
1. Reduce `-c` (frees KV VRAM → room for more GPU layers).
2. Enable `-fa 1` + `--cache-type-k q8_0 --cache-type-v q8_0` (halves KV footprint).
3. Drop to a smaller quant (Q5→Q4).
4. Use a smaller model — a fully-GPU 7B crushes a split 13B.

## "Starts fast, slows down mid-conversation"

The KV cache is filling. As filled context grows, every new token attends over more history; near
the VRAM limit the cache may also spill to system RAM.
Fix: shorter conversations, smaller `-c`, or q8_0 KV quantization to slow VRAM accumulation.

## "Only N tok/s, GPU looks idle"

Run the checks in order:
1. **Backend**: is the build GPU-enabled? (`--version`, look for CUDA/HIP/Metal). A CPU-only build
   silently runs everything on CPU → rebuild.
2. **Offload**: missing `-ngl 99` → the model may be on CPU. Add it; confirm in the log.
3. **Flag ignored**: if `-ngl` does nothing, the binary has no GPU support (rebuild).

## "Ollama is slower than bare llama.cpp"

Ollama adds ~5–15% HTTP overhead; more than that means config mismatch. Check `OLLAMA_DEBUG=1
ollama serve` logs for `offloaded X/Y`, and set `OLLAMA_FLASH_ATTENTION=1` (not always on by
default). Verify `OLLAMA_CONTEXT_LENGTH` and KV type match what you'd pass to llama.cpp. `ollama ps`
shows where the model landed.

## "Speed is erratic / sudden multi-second stalls"

Model on slow/network storage being paged during inference.
Fix: put GGUF on NVMe; or `--no-mmap` to load fully into RAM; or `--mlock` to pin it (needs
`ulimit -l unlimited`).

## "Increasing batch size did nothing"

Expected — `-b`/`-ub` affect **prefill**, not decode. If your complaint is chat responsiveness
(tg), batch size isn't the lever. If prompts/RAG ingest is slow, then raise `-b` (keep `-ub <= -b`;
raise `-b` when you raise `-ub`).

## "Speculative decoding made it slower"

Known. Causes: (a) low draft acceptance — check the logged acceptance rate; (b) both models
together cause partial offload; (c) MoE model — expert switching overhead exceeds the batching win
(measured −3% to −12% on Qwen3.6-35B-A3B); (d) `--draft-max` too large. Try `--draft-max 2–3`, or
disable. For MoE, prefer ngram or nothing.

## "Concurrency doesn't scale / users queue"

- `--ctx-size` is **total across slots** — verify per-slot context isn't starved (`-c / --parallel`).
- Check `/metrics`: `requests_deferred > 0` sustained = too few slots or too little context.
- 4 slots ≈ 1.3× aggregate throughput, not 4× — concurrency, not total speed.
- Past ~5–10 concurrent users, llama.cpp's scheduler is the bottleneck → move to vLLM
  (PagedAttention).

## "Mixed KV types / I set q8 K and q4 V"

You're losing ~40% throughput. Set both to the same type. This is the single most surprising
self-inflicted regression in the data.

## "It worked, then a rebuild changed things"

llama.cpp ships multiple builds/day and defaults shift between versions. Pin a known-good version,
read release notes, and re-run the baseline after upgrading.
