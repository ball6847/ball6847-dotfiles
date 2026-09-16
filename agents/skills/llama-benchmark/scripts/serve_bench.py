#!/usr/bin/env python3
"""Benchmark a running llama-server over its OpenAI-compatible HTTP API.

Measures time-to-first-token (TTFT), per-request throughput, and aggregate
throughput across concurrency levels. Stdlib only.

Example
-------
python serve_bench.py --url http://127.0.0.1:8080 \
    --prompt-tokens 512 --max-tokens 128 --concurrency 1,4,8 --reps 3 \
    --json serve-bench.json

Note: generated-token counts are approximated by counting streamed content
chunks (llama-server emits one SSE content delta per token in practice).
"""
from __future__ import annotations

import argparse
import http.client
import json
import ssl
import statistics
import sys
import threading
import time
from urllib.parse import urlparse

FILLER = ("the quick brown fox jumps over a lazy dog while sunlight "
          "warms the quiet valley and distant birds sing").split()


def make_prompt(n_tokens: int) -> str:
    """Approximate an n_tokens-long prompt (tokens ~ words)."""
    n = max(1, n_tokens)
    return " ".join(FILLER[i % len(FILLER)] for i in range(n))


def one_request(host, port, path, use_tls, model, prompt, max_tokens, api_key,
                barrier, out, idx):
    body = json.dumps({
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": max_tokens,
        "temperature": 0,
        "stream": True,
    }).encode()
    headers = {"Content-Type": "application/json"}
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"

    conn_cls = http.client.HTTPSConnection if use_tls else http.client.HTTPConnection
    ctx = ssl._create_unverified_context() if use_tls else None
    conn = conn_cls(host, port, timeout=600, context=ctx) if use_tls else conn_cls(host, port, timeout=600)

    barrier.wait()
    t0 = time.perf_counter()
    ttft = None
    n_chunks = 0
    try:
        conn.request("POST", path, body=body, headers=headers)
        resp = conn.getresponse()
        if resp.status != 200:
            out[idx] = {"error": f"HTTP {resp.status}: {resp.read()[:200]!r}"}
            return
        for raw in resp:
            line = raw.decode("utf-8", "replace").strip()
            if not line.startswith("data:"):
                continue
            data = line[5:].strip()
            if data == "[DONE]":
                break
            try:
                obj = json.loads(data)
            except json.JSONDecodeError:
                continue
            for ch in obj.get("choices", []):
                if (ch.get("delta") or {}).get("content"):
                    if ttft is None:
                        ttft = time.perf_counter() - t0
                    n_chunks += 1
    except Exception as e:  # noqa: BLE001 - report any transport failure
        out[idx] = {"error": f"{type(e).__name__}: {e}"}
        return
    finally:
        conn.close()

    total = time.perf_counter() - t0
    out[idx] = {"ttft": ttft, "total": total, "tokens": n_chunks,
                "tps": (n_chunks / (total - (ttft or 0))) if total > (ttft or 0) else None,
                "start": t0, "end": time.perf_counter()}


def run_level(host, port, path, use_tls, model, prompt, max_tokens, api_key, concurrency):
    barrier = threading.Barrier(concurrency)
    out: list = [None] * concurrency
    threads = [threading.Thread(target=one_request,
                                args=(host, port, path, use_tls, model, prompt, max_tokens,
                                      api_key, barrier, out, i)) for i in range(concurrency)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    errs = [r["error"] for r in out if r and "error" in r]
    ok = [r for r in out if r and "error" not in r]
    if not ok:
        return {"concurrency": concurrency, "errors": errs or ["no results"]}

    ttfts = [r["ttft"] for r in ok if r["ttft"] is not None]
    tpss = [r["tps"] for r in ok if r["tps"]]
    span = max(r["end"] for r in ok) - min(r["start"] for r in ok)
    total_tokens = sum(r["tokens"] for r in ok)
    return {
        "concurrency": concurrency,
        "per_request_tps_median": statistics.median(tpss) if tpss else None,
        "ttft_ms_median": statistics.median(ttfts) * 1000 if ttfts else None,
        "aggregate_tps": total_tokens / span if span > 0 else None,
        "errors": errs,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--url", default="http://127.0.0.1:8080")
    ap.add_argument("--model", default="local", help="value for the request 'model' field")
    ap.add_argument("--prompt-tokens", type=int, default=512)
    ap.add_argument("--max-tokens", type=int, default=128)
    ap.add_argument("--concurrency", default="1,4,8", help="comma list, e.g. 1,2,4,8")
    ap.add_argument("--reps", type=int, default=3)
    ap.add_argument("--api-key", default=None)
    ap.add_argument("--json", dest="json_out", default=None)
    args = ap.parse_args()

    u = urlparse(args.url if "://" in args.url else "http://" + args.url)
    host, port, use_tls = u.hostname, u.port or (443 if u.scheme == "https" else 80), u.scheme == "https"
    path = (u.path.rstrip("/") or "") + "/v1/chat/completions"
    prompt = make_prompt(args.prompt_tokens)
    levels = [int(c) for c in args.concurrency.split(",") if c.strip()]

    print(f"target: {u.scheme}://{host}:{port}{path}")
    print(f"prompt~{args.prompt_tokens} tok, max {args.max_tokens} tok, "
          f"concurrency {levels}, reps {args.reps}\n")

    summary = []
    for c in levels:
        runs = []
        for rep in range(args.reps):
            res = run_level(host, port, path, use_tls, args.model, prompt,
                            args.max_tokens, args.api_key, c)
            runs.append(res)
            if res.get("errors"):
                print(f"  c={c} rep={rep+1}: ERROR {res['errors'][0]}")
        valid = [r for r in runs if r.get("aggregate_tps")]
        if not valid:
            summary.append({"concurrency": c, "errors": runs[-1].get("errors")})
            continue
        row = {
            "concurrency": c,
            "ttft_ms_median": round(statistics.median(r["ttft_ms_median"] for r in valid), 1),
            "per_request_tps_median": round(statistics.median(r["per_request_tps_median"] for r in valid), 1),
            "aggregate_tps_median": round(statistics.median(r["aggregate_tps"] for r in valid), 1),
        }
        summary.append(row)
        print(f"  c={c:<3} TTFT {row['ttft_ms_median']:>8} ms | "
              f"per-req {row['per_request_tps_median']:>6} tok/s | "
              f"aggregate {row['aggregate_tps_median']:>7} tok/s")

    if args.json_out:
        with open(args.json_out, "w") as fh:
            json.dump({"url": args.url, "config": vars(args), "results": summary}, fh, indent=2)
        print(f"\nwrote {args.json_out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
