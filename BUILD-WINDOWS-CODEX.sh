#!/usr/bin/env bash
# Optional Windows x64 build using the same Godot 4.5.1 editor/templates as Android.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
GODOT_BIN="${GODOT_BIN:-$HOME/.local/bin/runebound-godot-4.5.1}"
export GODOT_BIN
VERSION="$(python3 -c 'import re,pathlib; print(re.search(r"config/version=\"([^\"]+)\"",pathlib.Path("project.godot").read_text())[1])')"
TEMPLATES="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/4.5.1.stable"
bash "$ROOT/BUILD-ANDROID-CODEX.sh" --engine-only
[[ -f "$TEMPLATES/windows_release_x86_64.exe" ]] || { echo >&2 "Godot Windows template missing: run BUILD-ANDROID-CODEX.sh first."; exit 1; }
mkdir -p builds/Windows builds/logs
# Generated legacy executable names must not leak into the renamed package.
rm -f builds/Windows/Runebound.exe builds/Windows/Runebound.pck
run_logged(){
 local log="$1"; shift
 "$GODOT_BIN" "$@" 2>&1 | tee "$log"
 if grep -Eq 'SCRIPT ERROR:|(^|[[:space:]])ERROR:' "$log"; then echo >&2 "Godot reported errors: $log"; exit 1; fi
}
run_logged builds/logs/windows-import.log --headless --path "$ROOT" --import
run_logged builds/logs/windows-export.log --headless --path "$ROOT" --export-release Windows "$ROOT/builds/Windows/Vyrnspire.exe"
[[ -s builds/Windows/Vyrnspire.exe && -s builds/Windows/Vyrnspire.pck ]] || { echo >&2 "Windows export incomplete"; exit 1; }
python3 tools/run_tests.py --godot "$GODOT_BIN" --pack "$ROOT/builds/Windows/Vyrnspire.pck" --suite test_mire_chapter --suite test_boss_signs --suite test_dungeon_atlas --suite test_beacons --suite test_side_caves --suite test_menu_position --suite test_controls --suite test_control_input --suite test_rotation --suite test_kingdoms --suite test_thornwatch --suite test_fieldcraft --suite test_crowd_relief --suite test_forge_chapter --suite test_brand_storage --suite test_crafting_batches --suite test_position_recovery --suite test_dreadwood --suite test_enemy_tactics --suite test_chapter --suite test_release_pack --suite test_fishing --suite test_survival_kit --suite test_stability --suite test_touch_combat --suite test_spellbook --output builds/windows-pack-tests
cp WINDOWS-START.txt builds/Windows/README.txt
cp LICENSE-GODOT.txt GODOT-THIRD-PARTY-NOTICES.txt builds/Windows/
printf '@echo off\ncd /d "%%~dp0"\nstart "" "%%~dp0Vyrnspire.exe" -- --safe-mode\n' > builds/Windows/Start-Low-Power.bat
printf '@echo off\ncd /d "%%~dp0"\nstart "" "%%~dp0Vyrnspire.exe" --rendering-driver opengl3\n' > builds/Windows/Start-OpenGL.bat
python3 - "$VERSION" <<'PY'
from pathlib import Path
import sys,zipfile
with zipfile.ZipFile('builds/Vyrnspire-Windows-v'+sys.argv[1]+'.zip','w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
    for p in sorted(Path('builds/Windows').iterdir()):
        if p.is_file(): z.write(p,p.name)
PY
echo "Windows export: $ROOT/builds/Vyrnspire-Windows-v$VERSION.zip"
