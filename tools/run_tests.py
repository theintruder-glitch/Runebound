#!/usr/bin/env python3
"""Run the real Godot suites with disposable per-test saves and strict log checks."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--godot', default=os.environ.get('GODOT_BIN', 'godot'))
parser.add_argument('--output', type=Path, default=ROOT / 'builds/test-results')
parser.add_argument('--suite', action='append', help='Test stem; repeat to select suites')
parser.add_argument('--display', action='store_true', help='Use an available X display for rendered checks')
parser.add_argument('--pack', type=Path, help='Exercise exported PCK resources with external test scripts')
parser.add_argument('--resources', type=Path, help='Exercise assets extracted from a signed APK')
args = parser.parse_args()
args.output = args.output.resolve()
args.output.mkdir(parents=True, exist_ok=True)
engine = shutil.which(args.godot)
if not engine:
    parser.error('Godot executable unavailable: ' + args.godot)
engine = str(Path(engine).resolve())
suites = args.suite or [p.stem for p in sorted((ROOT / 'tests').glob('test_*.gd')) if p.stem != 'test_release_pack']
if args.pack and args.resources:
    parser.error('Choose --pack or --resources')
if args.pack and not args.suite:
    parser.error('--pack requires explicit --suite choices')
errors = re.compile(r'(SCRIPT ERROR:|(?:^|\n)\s*ERROR:|FAIL:|Assertion failed)', re.I)
passed = re.compile(r'(?:CHECKS PASSED|ALL \d+ GODOT CHECKS PASSED|CHECKS; 0 FAILURES|AUTO PICKUP CHECKS:\s*\d+)', re.I)
results = []
for suite in suites:
    script = ROOT / 'tests' / (suite + '.gd')
    if not script.is_file():
        parser.error('Unknown suite: ' + suite)
    variants = [[], ['landscape']] if suite in ['test_movement', 'test_live_frames'] else [[]]
    for variant in variants:
        name = suite + ('-landscape' if variant else '')
        flags = ['--desktop'] if suite in ['test_desktop', 'test_desktop_boot', 'test_spellbook'] else []
        if suite in ['test_side_caves', 'test_beacons']:
            flags.append('--mobile')
        if suite == 'test_desktop_boot':
            flags.append('--safe-mode')
        if suite in ['test_controls', 'test_control_input', 'test_rotation', 'test_thornwatch', 'test_stability', 'test_touch_combat', 'test_chapter', 'test_enemy_tactics', 'test_dreadwood', 'test_position_recovery', 'test_crafting_batches', 'test_brand_storage', 'test_forge_chapter', 'test_crowd_relief', 'test_fieldcraft'] and args.pack:
            flags.append('--mobile')
        cmd = [engine] + ([] if args.display else ['--headless'])
        if args.pack:
            cmd += ['--main-pack', str(args.pack.resolve()), '--script', str(script)]
        elif args.resources:
            cmd += ['--path', str(args.resources.resolve()), '--script', str(script)]
        else:
            cmd += ['--path', str(ROOT), '--script', 'res://tests/' + script.name]
        cmd += ['--', *flags, *variant]
        start = time.monotonic()
        with tempfile.TemporaryDirectory(prefix='runebound-test-') as profile:
            env = {**os.environ, 'XDG_DATA_HOME': profile + '/data', 'XDG_CONFIG_HOME': profile + '/config', 'XDG_CACHE_HOME': profile + '/cache', 'GODOT_SILENCE_ROOT_WARNING': '1'}
            try:
                run = subprocess.run(cmd, env=env, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=120)
                log = run.stdout
                ok = run.returncode == 0 and not errors.search(log) and bool(passed.search(log))
                code = run.returncode
            except subprocess.TimeoutExpired as exc:
                log = (exc.stdout or b'').decode(errors='replace') if isinstance(exc.stdout, bytes) else exc.stdout or ''
                log += '\nFAIL: suite exceeded 120 seconds\n'
                ok, code = False, None
        (args.output / (name + '.log')).write_text(log)
        count = len(re.findall(r'^PASS:', log, re.M))
        if suite == 'test_desktop_boot' and ok: count = 1
        results.append({'suite': name, 'passed': ok, 'exit_code': code, 'checks': count, 'seconds': round(time.monotonic() - start, 2)})
        print(('PASS' if ok else 'FAIL') + f' {name}: {count} checks', flush=True)
        if not ok:
            print(log[-4000:], flush=True)
summary = {'engine': subprocess.check_output([engine, '--version'], text=True).strip(), 'mode': 'display' if args.display else 'headless', 'pack': str(args.pack) if args.pack else None, 'resources': str(args.resources) if args.resources else None, 'results': results, 'passed': all(r['passed'] for r in results)}
(args.output / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
raise SystemExit(0 if summary['passed'] else 1)
