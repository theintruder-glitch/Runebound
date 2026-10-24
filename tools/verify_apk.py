#!/usr/bin/env python3
"""Check the actual APK against the current export configuration."""
import configparser
import json
from pathlib import Path
import re
import struct
import sys
import zipfile

root = Path(__file__).resolve().parents[1]
cfg = configparser.ConfigParser(interpolation=None)
cfg.read(root / 'export_presets.cfg')
options = cfg['preset.0.options']
apk, badging = map(Path, sys.argv[1:])
text = badging.read_text()
package = re.search(r"^package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'", text, re.M)
assert package, 'aapt did not identify an APK package'
assert package[1] == json.loads(options['package/unique_name']) == 'app.runebound.godot', 'Package changed'
assert package[2] == options['version/code'] and int(package[2]) > 22, 'Version code must update v0.15.0'
assert package[3] == json.loads(options['version/name']), 'Version name mismatch'
assert "targetSdkVersion:'35'" in text and "sdkVersion:'24'" in text, 'Unexpected target/minimum SDK'
with zipfile.ZipFile(apk) as archive:
    assert archive.testzip() is None, 'APK CRC failure'
    names = archive.namelist()
    libs = [n for n in names if n.startswith('lib/') and n.endswith('.so')]
    assert libs and all(n.startswith('lib/arm64-v8a/') for n in libs), 'Expected ARM64 only'
    assert 'AndroidManifest.xml' in names and 'classes.dex' in names, 'Missing runtime files'
    assert any('game.gd' in n or n.endswith('.pck') for n in names), 'Game resources missing'
    assert not any('runebound-local.jks' in n or n.startswith('assets/tests/') or n.startswith('assets/migration/') for n in names), 'Private/development files leaked into APK'
    for name in libs:
        data = archive.read(name)
        assert data[:6] == b'\x7fELF\x02\x01', 'Expected little-endian ELF64'
        offset = struct.unpack_from('<Q', data, 32)[0]
        size, count = struct.unpack_from('<HH', data, 54)
        for index in range(count):
            ph = offset + index * size
            kind = struct.unpack_from('<I', data, ph)[0]
            if kind == 1:
                align = struct.unpack_from('<Q', data, ph + 48)[0]
                assert align >= 16384, 'Native LOAD segment lacks 16 KB page alignment: ' + name
print(f'APK VERIFIED: {package[1]}, code {package[2]}, {package[3]}, ARM64, API 24–35, ELF 16 KB alignment')
