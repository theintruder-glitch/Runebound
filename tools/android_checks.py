#!/usr/bin/env python3
"""Run the Android regression suites with disposable, isolated save profiles."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
ERROR = re.compile(r"SCRIPT ERROR:|ERROR:|FAIL:|Assertion failed")
SUITES = ["game", "survival", "forest", "expansion", "presentation", "contracts",
          "weather", "trader", "farming", "auto_pickup", "menu_scroll", "rotation",
          "movement", "live_frames", "mobile_controls", "needs", "wilderness"]


def run_logged(command, log, env, timeout=180):
    try:
        result = subprocess.run(command, env=env, cwd=ROOT, capture_output=True,
                                text=True, timeout=timeout)
        output = result.stdout + result.stderr
        log.write_text(output)
        if result.returncode or ERROR.search(output):
            raise RuntimeError(f"Failed: {log.name}\n{output[-5000:]}")
        return output
    except subprocess.TimeoutExpired as error:
        log.write_bytes((error.stdout or b"") + (error.stderr or b""))
        raise RuntimeError(f"Timed out: {log.name}") from error


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=os.environ.get("GODOT_BIN", "godot"))
    parser.add_argument("--logs", type=Path, default=ROOT / "builds/logs")
    parser.add_argument("--suite", action="append", choices=SUITES)
    args = parser.parse_args()
    args.logs.mkdir(parents=True, exist_ok=True)
    results = []
    with tempfile.TemporaryDirectory(prefix="runebound-tests-") as temporary:
        for suite in args.suite or SUITES:
            modes = ["portrait", "landscape"] if suite in ["movement", "live_frames", "mobile_controls", "needs", "wilderness"] else ["portrait"]
            for mode in modes:
                name = f"{suite}-{mode}"
                env = dict(os.environ, XDG_DATA_HOME=str(Path(temporary) / name))
                output = run_logged([args.godot, "--headless", "--path", str(ROOT),
                                     "--script", f"res://tests/test_{suite}.gd", "--", mode],
                                    args.logs / f"{name}.log", env)
                checks = len(re.findall(r"^PASS:", output, re.M))
                if not checks:
                    raise RuntimeError(f"{name}: no passing assertions were recorded")
                results.append({"suite": name, "checks": checks, "passed": True})
                print(f"PASS {name}: {checks} checks", flush=True)
    (args.logs / "tests.json").write_text(json.dumps(results, indent=2) + "\n")
    print(f"{len(results)} runs, {sum(r['checks'] for r in results)} checks passed")


if __name__ == "__main__":
    main()
