#!/usr/bin/env bash
# Runebound pinned Linux toolchain and verified APK export.
set -Eeuo pipefail
IFS=$'\n\t'
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
GODOT_VERSION="4.5.1"
GODOT_TAG="4.5.1-stable"
GODOT_EXE_DEFAULT="$HOME/.local/bin/runebound-godot-4.5.1"
GODOT_EXE="${GODOT_BIN:-$GODOT_EXE_DEFAULT}"
SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Android/Sdk}}"
TEMPLATE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/4.5.1.stable"
EDITOR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/godot"
EDITOR_CFG="$EDITOR_DIR/editor_settings-4.5.tres"
VERSION="$(python3 -c 'import re,pathlib; print(re.search(r"config/version=\"([^\"]+)\"",pathlib.Path("project.godot").read_text())[1])')"
OUTPUT="$ROOT/builds/Vyrnspire-Godot-v$VERSION.apk"
KEYSTORE="${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:-$ROOT/signing/runebound-local.jks}"
GODOT_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_TAG}/Godot_v4.5.1-stable_linux.x86_64.zip"
GODOT_SHA="02ec53d1cc7dbb9cc6355393c61b9ab43d1244751a124f10248a4802830788cd"
TEMPLATE_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_TAG}/Godot_v4.5.1-stable_export_templates.tpz"
TEMPLATE_SHA="1998af37f1387684e2c211cdb483daf492fc64dc6b12096bddcdca25b6910c86"
ANDROID_CLI_URL="https://dl.google.com/android/repository/commandlinetools-linux-15859902_latest.zip"
ANDROID_CLI_SHA="4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583"

fail(){ echo >&2 "[ERROR] $*"; exit 1; }
msg(){ printf '\n[VYRNSPIRE] %s\n' "$*"; }
usage(){ cat <<'EOF'
VYRNSPIRE native APK export on 64-bit Linux (including Codex cloud workspaces).
Usage: bash BUILD-ANDROID-CODEX.sh [--check-only] [--engine-only] [--skip-test] [--accept-sdk-licenses]
  --check-only           Print detected dependencies; download/build nothing.
  --engine-only          Install pinned engine/templates without SDK or signing.
  --skip-test            Skip full regression suites; import still runs.
  --accept-sdk-licenses  You explicitly agree to Android SDK licenses; run sdkmanager --licenses noninteractively.
Environment: GODOT_BIN, ANDROID_SDK_ROOT, JAVA_HOME, GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD.
Downloads are large; allow several GB of disk space. Does not modify the game or its saved characters.
EOF
}
CHECK_ONLY=0; SKIP_TEST=0; ACCEPT_LICENSES=0; ENGINE_ONLY=0
for arg in "$@"; do
 case "$arg" in
  --check-only) CHECK_ONLY=1;;
  --engine-only) ENGINE_ONLY=1;;
  --skip-test) SKIP_TEST=1;;
  --accept-sdk-licenses) ACCEPT_LICENSES=1;;
  --help|-h) usage; exit 0;;
  *) usage; fail "Unknown argument: $arg";;
 esac
done
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || fail "This helper requires Linux x86_64 (Codex). Android-on-phone/Windows uses a different setup."
for cmd in bash unzip python3 sha256sum; do command -v "$cmd" >/dev/null || fail "Missing: $cmd"; done
if ! command -v curl >/dev/null && ! command -v wget >/dev/null; then fail "Install curl or wget"; fi
if [[ "$GODOT_EXE" != */* ]]; then GODOT_EXE="$(command -v "$GODOT_EXE" || true)"; fi
if [[ -z "$GODOT_EXE" ]]; then GODOT_EXE="$GODOT_EXE_DEFAULT"; fi
msg "Godot executable: $GODOT_EXE"
msg "Android SDK directory: $SDK"
msg "Templates: $TEMPLATE_DIR"
msg "Java: $(command -v java || printf 'missing')"
if ((CHECK_ONLY)); then
 [[ -x "$GODOT_EXE" ]] && "$GODOT_EXE" --version || true
 [[ -x "$SDK/cmdline-tools/latest/bin/sdkmanager" ]] && echo "SDK manager present" || echo "SDK manager missing"
 [[ -f "$TEMPLATE_DIR/android_release.apk" ]] && echo "Android export template present" || echo "Android export template missing"
 [[ -f "$KEYSTORE" ]] && echo "Existing prototype signing key present" || echo "Signing key missing"
 exit 0
fi
[[ -f "$ROOT/project.godot" && -f "$ROOT/export_presets.cfg" ]] || fail "Run from within extracted Runebound Godot source."
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fetch(){
 local url="$1" target="$2" hash="$3"
 if [[ -f "$target" ]] && echo "$hash  $target" | sha256sum --status -c -; then echo "Verified cached $(basename "$target")"; return; fi
 msg "Downloading $(basename "$target")"
 if command -v curl >/dev/null; then curl --fail --location --retry 3 --connect-timeout 30 "$url" -o "$target" || fail "Download failed. Check workspace internet access: $url"
 else wget --tries=3 -O "$target" "$url" || fail "Download failed. Check workspace internet access: $url"; fi
 echo "$hash  $target" | sha256sum --status -c - || fail "SHA-256 mismatch for $target (download discarded)"
}
if [[ ! -x "$GODOT_EXE" ]]; then
 fetch "$GODOT_URL" "$TMP/godot.zip" "$GODOT_SHA"
 mkdir -p "$(dirname "$GODOT_EXE")"
 unzip -qp "$TMP/godot.zip" 'Godot_v4.5.1-stable_linux.x86_64' > "$GODOT_EXE" || fail "Unable to extract Godot editor"
 chmod +x "$GODOT_EXE"
fi
"$GODOT_EXE" --version | grep -q '^4\.5\.1' || fail "Wrong Godot version. Runebound expects Godot 4.5.1 and matching templates."
if [[ ! -f "$TEMPLATE_DIR/android_release.apk" || ! -f "$TEMPLATE_DIR/windows_release_x86_64.exe" ]]; then
 fetch "$TEMPLATE_URL" "$TMP/templates.tpz" "$TEMPLATE_SHA"
 mkdir -p "$TMP/templates-extracted" "$TEMPLATE_DIR"
 unzip -oq "$TMP/templates.tpz" 'templates/*' -d "$TMP/templates-extracted" || fail "Could not extract templates"
 cp -a "$TMP/templates-extracted/templates/." "$TEMPLATE_DIR/" || fail "Could not install export templates"
fi
[[ -s "$TEMPLATE_DIR/android_release.apk" ]] || fail "android_release.apk template missing"
[[ -s "$TEMPLATE_DIR/android_debug.apk" ]] || fail "android_debug.apk template missing"
if ((ENGINE_ONLY)); then msg "Pinned engine/templates ready"; exit 0; fi
[[ -f "$KEYSTORE" ]] || fail "Original signing key missing; set GODOT_ANDROID_KEYSTORE_RELEASE_PATH. Never generate a replacement for an update."
[[ -n "${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:-}" ]] || fail "Set GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD securely for the original key."
# Keep JDK selection aligned with Godot's configuration; 17 is preferred, 17+ supported.
if [[ -z "${JAVA_HOME:-}" ]]; then
 if command -v java >/dev/null; then JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"; else fail "Install OpenJDK 17 and rerun; no Java runtime was found."; fi
fi
[[ -x "$JAVA_HOME/bin/java" && -x "$JAVA_HOME/bin/keytool" ]] || fail "JAVA_HOME must point at a JDK with java and keytool, ideally Java 17."
JAVA_MAJOR="$($JAVA_HOME/bin/java -version 2>&1 | sed -nE '1s/.*version "(1\.)?([0-9]+).*/\2/p')"
[[ "$JAVA_MAJOR" =~ ^[0-9]+$ ]] && ((JAVA_MAJOR>=17)) || fail "Need JDK 17 or newer. Found: $JAVA_MAJOR"
export JAVA_HOME ANDROID_HOME="$SDK" ANDROID_SDK_ROOT="$SDK"
if [[ ! -x "$SDK/cmdline-tools/latest/bin/sdkmanager" ]]; then
 fetch "$ANDROID_CLI_URL" "$TMP/android-cli.zip" "$ANDROID_CLI_SHA"
 mkdir -p "$TMP/sdk-tools" "$SDK/cmdline-tools"
 unzip -q "$TMP/android-cli.zip" -d "$TMP/sdk-tools"
 [[ -x "$TMP/sdk-tools/cmdline-tools/bin/sdkmanager" ]] || fail "Google SDK archive missing sdkmanager"
 [[ ! -e "$SDK/cmdline-tools/latest" ]] || fail "Incomplete SDK at $SDK/cmdline-tools/latest; repair that path before retrying"
 mv "$TMP/sdk-tools/cmdline-tools" "$SDK/cmdline-tools/latest"
fi
SDKMANAGER="$SDK/cmdline-tools/latest/bin/sdkmanager"
if ((ACCEPT_LICENSES)); then
 msg "Accepting SDK licenses at your explicit request"
 (yes || true) | "$SDKMANAGER" --sdk_root="$SDK" --licenses >/dev/null || fail "SDK licenses could not be accepted"
elif [[ ! -d "$SDK/licenses" ]]; then
 msg "Android SDK licenses must be reviewed and accepted before installing packages."
 msg "Run: $SDKMANAGER --sdk_root=\"$SDK\" --licenses"
 fail "Review licenses, then rerun. Or explicitly opt in using --accept-sdk-licenses."
fi
if [[ ! -x "$SDK/platform-tools/adb" || ! -f "$SDK/build-tools/35.0.1/apksigner" || ! -f "$SDK/platforms/android-35/android.jar" ]]; then
 msg "Installing Android 35 SDK and build-tools 35.0.1 (prebuilt APK export; no native compilation)"
 "$SDKMANAGER" --sdk_root="$SDK" "platform-tools" 'build-tools;35.0.1' 'platforms;android-35' || fail "SDK package installation failed; inspect SDK manager output"
fi
# Some recent Google CLI installs retain the archive's android-15 wrapper.
# Only normalize the verified 35.0.1 payload when the canonical tools are absent.
python3 - "$SDK/build-tools/35.0.1" <<'PYSDK'
from pathlib import Path
import sys
root=Path(sys.argv[1]);nested=root/'android-15'
if not (root/'apksigner').is_file() and (nested/'apksigner').is_file():
    props=(nested/'source.properties').read_text()
    if 'Pkg.Revision=35.0.1' not in props.replace(' ', ''):
        raise SystemExit('Nested Android build-tools revision differs from 35.0.1; refusing to change it.')
    children=list(nested.iterdir())
    if any((root/p.name).exists() for p in children):
        raise SystemExit('Conflicting nested build-tools files; repair the SDK before exporting.')
    for item in children: item.rename(root/item.name)
    nested.rmdir()
    print('Normalized official Android Build-Tools 35.0.1 archive directory.')
PYSDK
[[ -x "$SDK/platform-tools/adb" ]] || fail "SDK platform-tools/adb missing"
[[ -f "$SDK/build-tools/35.0.1/apksigner" ]] || fail "Android Build-Tools 35.0.1 missing"
# Godot 4.5 uses a per-minor-version EditorSettings file, outside the project.
mkdir -p "$EDITOR_DIR"
python3 - "$EDITOR_CFG" "$JAVA_HOME" "$SDK" <<'PY'
import pathlib, re, sys
p=pathlib.Path(sys.argv[1])
s=p.read_text() if p.is_file() else '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
if '[resource]' not in s:
    raise SystemExit('Unexpected editor settings format; configure Android and Java SDK paths manually')
for key,value in [('export/android/java_sdk_path',sys.argv[2]),('export/android/android_sdk_path',sys.argv[3])]:
    statement=f'{key} = "{value}"'
    pat=rf'(?m)^{re.escape(key)}\s*=.*$'
    if re.search(pat,s): s=re.sub(pat,lambda m:statement,s,count=1)
    else: s=s.rstrip()+'\n'+statement+'\n'
p.write_text(s)
PY
mkdir -p "$ROOT/builds/logs"
run_logged(){
 local log="$1"; shift
 "$GODOT_EXE" "$@" 2>&1 | tee "$log" || fail "Godot command failed: $log"
 if grep -Eq 'SCRIPT ERROR:|(^|[[:space:]])ERROR:' "$log"; then fail "Godot reported errors: $log"; fi
}
run_logged "$ROOT/builds/logs/android-import.log" --headless --path "$ROOT" --import
if ((!SKIP_TEST)); then python3 tools/run_tests.py --godot "$GODOT_EXE" || fail "Regression checks failed"; fi
# The existing .jks is a deliberately shared *prototype* key from this project's prior builds.
# Never silently generate a replacement: that would prevent in-place installs and could lose saves.
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$KEYSTORE"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="${GODOT_ANDROID_KEYSTORE_RELEASE_USER:-runebound}"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
msg "Exporting signed Android ARM64 APK"
mkdir -p "$ROOT/builds"
run_logged "$ROOT/builds/logs/android-export.log" --headless --path "$ROOT" --export-release Android "$OUTPUT"
[[ -s "$OUTPUT" ]] || fail "Export returned without creating an APK"
unzip -tqq "$OUTPUT" || fail "APK ZIP integrity check failed"
SIGNATURE_INFO="$("$SDK/build-tools/35.0.1/apksigner" verify --verbose --print-certs "$OUTPUT")" || fail "APK signature verification failed"
printf "%s\n" "$SIGNATURE_INFO"
echo "$SIGNATURE_INFO" | grep -qi "79a1ef0f60f3b4c6e65bd42cc422b28c7e969dd5ae54b0ddc77242f9287bab37" || fail "APK signing certificate changed: do not install over existing version"
"$SDK/build-tools/35.0.1/aapt" dump badging "$OUTPUT" > "$ROOT/builds/logs/android-badging.log"
python3 tools/verify_apk.py "$OUTPUT" "$ROOT/builds/logs/android-badging.log" || fail "APK package/ABI/version checks failed"
"$SDK/build-tools/35.0.1/zipalign" -c -P 16 -v 4 "$OUTPUT" > "$ROOT/builds/logs/android-alignment.log" || fail "APK alignment check failed"
VERIFIED_CHECKSUM="$(sha256sum "$OUTPUT")"
GODOT_BIN="$GODOT_EXE" python3 tools/test_apk.py "$OUTPUT" || fail "Signed APK resource tests failed"
[[ "$(sha256sum "$OUTPUT")" == "$VERIFIED_CHECKSUM" ]] || fail "APK changed during resource testing; refusing to publish it"
"$SDK/build-tools/35.0.1/apksigner" verify --verbose "$OUTPUT" || fail "Final APK signature verification failed"
if command -v sha256sum >/dev/null; then sha256sum "$OUTPUT"; fi
msg "SUCCESS: $OUTPUT"
msg "Install over the existing Godot app; do not uninstall or clear its data. For any later version, raise version/code in export_presets.cfg."
