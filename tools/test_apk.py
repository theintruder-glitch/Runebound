#!/usr/bin/env python3
"""Exercise exact compiled resources extracted from the signed APK."""
from pathlib import Path, PurePosixPath
import subprocess
import sys
import tempfile
import zipfile

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='runebound-apk-') as temp:
    resources = Path(temp)
    with zipfile.ZipFile(sys.argv[1]) as apk:
        for name in apk.namelist():
            if not name.startswith('assets/') or name.endswith('/'):
                continue
            relative = PurePosixPath(name).relative_to('assets')
            if '..' in relative.parts:
                raise SystemExit('Unsafe APK resource path')
            target = resources / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(apk.read(name))
    command = [sys.executable, str(root / 'tools/run_tests.py'), '--resources', str(resources), '--output', str(root / 'builds/android-pack-tests')]
    for suite in ['test_crafting_batches', 'test_position_recovery', 'test_dreadwood', 'test_enemy_tactics', 'test_chapter', 'test_stability', 'test_touch_combat', 'test_game', 'test_expedition', 'test_fishing', 'test_fishing_touch']:
        command += ['--suite', suite]
    raise SystemExit(subprocess.run(command).returncode)
