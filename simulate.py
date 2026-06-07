#!/usr/bin/env python3

import shutil
import subprocess
import sys
from pathlib import Path

SRC_DIR   = Path("src")
SIM_DIR   = Path("sim")
BUILD_DIR = Path("build")

def find_pairs():
    pairs = []
    for tb in sorted(SIM_DIR.glob("*_tb.sv")):
        module = tb.stem.removesuffix("_tb")
        src = SRC_DIR / f"{module}.sv"
        if src.exists():
            pairs.append((module, src, tb))
        else:
            print(f"  WARN  {module}: testbench found but no matching src/{module}.sv")
    return pairs

def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)

def simulate(module, src, tb):
    if BUILD_DIR.exists():
        shutil.rmtree(BUILD_DIR)
    BUILD_DIR.mkdir()
    vvp = BUILD_DIR / f"{module}.vvp"

    # compile
    result = run(["iverilog", "-g2012", "-o", str(vvp), str(src), str(tb)])
    if result.returncode != 0:
        return "COMPILE FAIL", result.stderr.strip()

    # simulate
    result = run(["vvp", str(vvp)])
    if result.returncode != 0:
        return "FAIL", result.stdout.strip()

    return "PASS", None

def wave(module):
    vcd = BUILD_DIR / f"{module}.vcd"
    if not vcd.exists():
        pairs = find_pairs()
        match = next((p for p in pairs if p[0] == module), None)
        if not match:
            print(f"No module/testbench pair found for '{module}'")
            sys.exit(1)
        status, detail = simulate(*match)
        if status != "PASS":
            print(f"Simulation failed:\n{detail}")
            sys.exit(1)
    subprocess.Popen(["gtkwave", str(vcd)])

def main():
    import argparse
    parser = argparse.ArgumentParser(description="HDL simulation runner")
    parser.add_argument("module", nargs="?", help="Simulate and open GTKWave for a specific module")
    args = parser.parse_args()

    if args.module:
        wave(args.module)
        return

    pairs = find_pairs()
    if not pairs:
        print("No module/testbench pairs found.")
        sys.exit(1)

    print(f"\nRunning {len(pairs)} simulation(s)...\n")

    results = []
    for module, src, tb in pairs:
        status, detail = simulate(module, src, tb)
        results.append((module, status))
        marker = "✓" if status == "PASS" else "✗"
        print(f"  {marker}  {module:<30} {status}")
        if detail:
            for line in detail.splitlines():
                print(f"       {line}")

    passed = sum(1 for _, s in results if s == "PASS")
    failed = len(results) - passed

    print(f"\n{passed}/{len(results)} passed", end="")
    print(f", {failed} failed" if failed else "")
    print()

    sys.exit(0 if failed == 0 else 1)

if __name__ == "__main__":
    main()