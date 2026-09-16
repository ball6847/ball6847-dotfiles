#!/usr/bin/env python3
"""Sweep llama-bench over parameter combinations and report pp/tg.

Examples
--------
# Context sweep
python sweep.py --model m.gguf --base "-ngl 99 -fa 1" \
    --sweep "-c=4096,8192,16384,32768" -p 512 -n 128 -r 3 --out bench/

# KV cache sweep (matched K/V pairs -> q8_0/q8_0 and q4_0/q4_0, never mixed)
python sweep.py --model m.gguf --base "-ngl 99 -fa 1" \
    --sweep "-ctk=q8_0,q4_0 -ctv=q8_0,q4_0" --out bench/

# Print the plan without running anything
python sweep.py --model m.gguf --sweep "-c=4096,8192" --dry-run

A sweep dimension is one or more FLAG=v1,v2,... tokens. Tokens in the same
dimension are zipped positionally, so "-ctk=q8_0,q4_0 -ctv=q8_0,q4_0" yields the
matched pairs q8_0/q8_0 and q4_0/q4_0 (not the 4-way cartesian product).
Dimensions are combined as a cartesian product.
"""
from __future__ import annotations

import argparse
import itertools
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

NUM = re.compile(r"[-+]?\d*\.?\d+")


def parse_dimension(spec: str) -> list[list[tuple[str, str]]]:
    """Parse '-c=4096,8192' or '-ctk=a,b -ctv=a,b' into per-combo flag lists."""
    tokens = spec.split()
    flags, value_lists = [], []
    for tok in tokens:
        if "=" not in tok:
            sys.exit(f"error: sweep token {tok!r} must look like FLAG=v1,v2")
        flag, raw = tok.split("=", 1)
        vals = [v for v in raw.split(",") if v != ""]
        if not vals:
            sys.exit(f"error: sweep token {tok!r} has no values")
        flags.append(flag)
        value_lists.append(vals)

    length = max(len(v) for v in value_lists)
    if any(len(v) not in (1, length) for v in value_lists):
        sys.exit(f"error: in {spec!r}, value lists must be length 1 or all equal")
    combos = []
    for i in range(length):
        combos.append([(f, vl[i % len(vl)]) for f, vl in zip(flags, value_lists)])
    return combos


def build_matrix(specs: list[str]) -> list[list[tuple[str, str]]]:
    dims = [parse_dimension(s) for s in specs] if specs else [[]]
    return [list(itertools.chain.from_iterable(c)) for c in itertools.product(*dims)]


def find_bin(name: str) -> str | None:
    if Path(name).exists():
        return name
    found = shutil.which(name)
    if found:
        return found
    for cand in (Path("./build/bin") / name, Path("./bin") / name):
        if cand.exists():
            return str(cand)
    return None


def parse_bench(output: str) -> dict:
    """Extract pp/tg t/s from llama-bench's markdown table."""
    out: dict[str, float] = {}
    header: list[str] | None = None
    for line in output.splitlines():
        if "|" not in line:
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if header is None:
            low = [c.lower() for c in cells]
            if "test" in low and "t/s" in low:
                header = low
            continue
        if set("".join(cells)) <= set("-: "):
            continue
        if "test" not in header or "t/s" not in header:
            continue
        try:
            test = cells[header.index("test")]
            ts = cells[header.index("t/s")]
        except IndexError:
            continue
        m = NUM.search(ts.replace(",", ""))
        if m:
            key = test.split()[0]  # pp512-... -> pp512 ; tg128 -> tg128
            out[key] = float(m.group())
    return out


def normalize_argv(argv: list[str], opts: set[str]) -> list[str]:
    """Rewrite `--opt value` -> `--opt=value` so values may start with '-'.

    argparse treats a following token that begins with '-' as another option,
    which breaks natural usage like `--base "-ngl 99 -fa 1"`.
    """
    out: list[str] = []
    i = 0
    while i < len(argv):
        a = argv[i]
        if a in opts and i + 1 < len(argv) and not argv[i + 1].startswith("--"):
            out.append(f"{a}={argv[i + 1]}")
            i += 2
        else:
            out.append(a)
            i += 1
    return out


def main() -> int:
    sys.argv = normalize_argv(sys.argv, {"--base", "--sweep"})
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--model", required=True, help="path to GGUF model")
    ap.add_argument("--bin", default="llama-bench", help="llama-bench binary (default: search PATH)")
    ap.add_argument("--base", default="-ngl 99 -fa 1", help="flags applied to every config")
    ap.add_argument("--sweep", action="append", default=[], help="FLAG=v1,v2 (repeatable)")
    ap.add_argument("-p", "--prompt", default="512", help="prefill tokens (comma list allowed)")
    ap.add_argument("-n", "--gen", default="128", help="generation tokens")
    ap.add_argument("-r", "--reps", type=int, default=3, help="repeats per config")
    ap.add_argument("--out", default="bench-out", help="output directory")
    ap.add_argument("--dry-run", action="store_true", help="print commands, run nothing")
    args = ap.parse_args()

    matrix = build_matrix(args.sweep)
    binary = args.bin if args.dry_run else find_bin(args.bin)
    if not args.dry_run and not binary:
        sys.exit(f"error: could not find {args.bin!r}. Pass --bin /path/to/llama-bench")
    if not Path(args.model).exists() and not args.dry_run:
        sys.exit(f"error: model not found: {args.model}")

    base = args.base.split()
    print(f"{len(matrix)} config(s) to benchmark\n")

    results = []
    for idx, combo in enumerate(matrix, 1):
        flag_args = [x for f, v in combo for x in (f, v)]
        cmd = [binary or args.bin, "-m", args.model, *base, *flag_args,
               "-p", args.prompt, "-n", args.gen, "-r", str(args.reps)]
        label = " ".join(f"{f} {v}" for f, v in combo) or "(base)"
        print(f"[{idx}/{len(matrix)}] {label}", flush=True)

        if args.dry_run:
            print("    " + " ".join(cmd))
            continue

        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            print(f"    FAILED rc={proc.returncode}: {proc.stderr.strip()[:200]}")
            results.append({"label": label, "flags": flag_args, "error": proc.stderr.strip()[:500]})
            continue
        metrics = parse_bench(proc.stdout)
        tg = metrics.get(f"tg{args.gen}")
        pp = metrics.get(f"pp{args.prompt.split(',')[0]}")
        print(f"    pp={pp} tg={tg}")
        results.append({"label": label, "flags": flag_args, "pp": pp, "tg": tg})

    if args.dry_run:
        return 0

    outdir = Path(args.out)
    outdir.mkdir(parents=True, exist_ok=True)
    (outdir / "results.json").write_text(json.dumps({
        "model": args.model, "base": args.base, "prompt": args.prompt,
        "gen": args.gen, "reps": args.reps, "results": results}, indent=2))

    ranked = sorted([r for r in results if r.get("tg")], key=lambda r: r["tg"], reverse=True)
    lines = [f"# Benchmark report", "",
             f"- model: `{args.model}`", f"- base flags: `{args.base}`",
             f"- prefill `-p {args.prompt}`, generate `-n {args.gen}`, repeats {args.reps}", "",
             "| rank | config | pp t/s | tg t/s |", "|---|---|---|---|"]
    for i, r in enumerate(ranked, 1):
        lines.append(f"| {i} | `{r['label']}` | {r.get('pp')} | **{r['tg']}** |")
    failed = [r for r in results if r.get("error")]
    if failed:
        lines += ["", "## Failed configs", ""] + [f"- `{r['label']}`: {r['error'][:200]}" for r in failed]
    if ranked:
        lines += ["", f"**Best tg:** `{ranked[0]['label']}` at {ranked[0]['tg']} t/s"]
    (outdir / "report.md").write_text("\n".join(lines) + "\n")

    print(f"\nwrote {outdir/'results.json'} and {outdir/'report.md'}")
    if ranked:
        print(f"best tg: {ranked[0]['tg']} t/s  ({ranked[0]['label']})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
