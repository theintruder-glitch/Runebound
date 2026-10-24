#!/usr/bin/env python3
"""Import, test, export and verify Runebound without changing its export preset."""
import argparse
import base64
import hashlib
import json
import os
import configparser
import re
from pathlib import Path
import subprocess
import tempfile

from android_checks import ROOT, run_logged
from verify_android import verify
from signing_policy import signing_inputs, update_version


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=["check", "original", "updates"], default="check")
    parser.add_argument("--version-code")
    args = parser.parse_args()
    credentials = None if args.mode == "check" else signing_inputs(args.mode, os.environ)
    config = configparser.ConfigParser(interpolation=None)
    config.read(ROOT / "export_presets.cfg")
    version_code = None if args.mode == "check" else update_version(args.version_code, int(config["preset.0.options"]["version/code"]))
    engine = os.environ.get("GODOT_BIN", "godot")
    sdk = Path(os.environ["ANDROID_HOME"])
    java = Path(os.environ["JAVA_HOME"])
    version = subprocess.check_output([engine, "--version"], text=True)
    if not version.strip().startswith("4.5.1.stable."):
        raise RuntimeError(f"Expected Godot 4.5.1 stable, got {version}")
    for binary in [sdk / "platform-tools/adb", sdk / "platforms/android-35/android.jar",
                   sdk / "build-tools/35.0.0/apksigner", java / "bin/keytool"]:
        if not binary.is_file():
            raise RuntimeError(f"Required Android tool missing: {binary}")
    output = ROOT / "builds" / args.mode
    logs = output / "logs"
    logs.mkdir(parents=True, exist_ok=True)
    original = {name: (ROOT / name).read_bytes() for name in ["project.godot", "export_presets.cfg"]}
    with tempfile.TemporaryDirectory(prefix="runebound-build-") as temp:
        temporary = Path(temp)
        env = dict(os.environ)
        # Never write to the developer's editor settings or live save directory.
        for category in ["CONFIG", "CACHE"]:
            env[f"XDG_{category}_HOME"] = str(temporary / category.lower())
        env["XDG_DATA_HOME"] = str(temporary / "data")
        data = Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share")))
        templates = data / "godot/export_templates/4.5.1.stable"
        if not (templates / "android_debug.apk").is_file():
            raise RuntimeError(f"Matching Android template missing: {templates}")
        target = temporary / "data/godot/export_templates"
        target.mkdir(parents=True)
        (target / "4.5.1.stable").symlink_to(templates, target_is_directory=True)
        expected = None
        key = temporary / "signing.keystore"
        if credentials:
            encoded, alias, password, pinned = credentials
            key.write_bytes(base64.b64decode(encoded, validate=True))
            key.chmod(0o600)
            env.update(GODOT_ANDROID_KEYSTORE_DEBUG_PATH=str(key),
                       GODOT_ANDROID_KEYSTORE_DEBUG_USER=alias,
                       GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=password)
            cert = temporary / "certificate.der"
            subprocess.run([str(java / "bin/keytool"), "-exportcert", "-keystore", str(key),
                            "-alias", alias, "-storepass:env", "GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD",
                            "-file", str(cert)], env=env, check=True, capture_output=True)
            expected = hashlib.sha256(cert.read_bytes()).hexdigest()
            if expected != pinned:
                raise RuntimeError("Signing key differs from pinned certificate; refusing update build")
        settings = temporary / "config/godot/editor_settings-4.5.tres"
        settings.parent.mkdir(parents=True)
        values = {"export/android/java_sdk_path": str(java),
                  "export/android/android_sdk_path": str(sdk),
                  "export/android/shutdown_adb_on_exit": False}
        if credentials:
            values["export/android/debug_keystore"] = str(key)
        settings.write_text('[gd_resource type="EditorSettings" format=3]\n\n[resource]\n' +
                            "".join(f"{k} = {json.dumps(v)}\n" for k, v in values.items()))
        run_logged([engine, "--headless", "--path", str(ROOT), "--editor", "--import"], logs / "import.log", env)
        run_logged(["python3", str(ROOT / "tools/android_checks.py"), "--godot", engine,
                    "--logs", str(logs)], logs / "test-summary.log", env, timeout=600)
        if args.mode == "check":
            print("Checks passed. No installable APK requested or published.")
            return
        apk = output / f"Runebound-Android-update-{version_code}.apk"
        # Only the build's version metadata changes; restore the exact preset even on failure.
        preset = ROOT / "export_presets.cfg"
        text = original["export_presets.cfg"].decode()
        text, count = re.subn(r"(?m)^version/code=\d+$", f"version/code={version_code}", text)
        if count != 1:
            raise RuntimeError("Expected exactly one Android version code")
        try:
            preset.write_text(text)
            run_logged([engine, "--headless", "--path", str(ROOT), "--export-debug", "Android", str(apk)],
                       logs / "export.log", env, timeout=300)
        finally:
            preset.write_bytes(original["export_presets.cfg"])
        for name, content in original.items():
            if (ROOT / name).read_bytes() != content:
                raise RuntimeError(f"Build changed {name}")
        verify(apk, sdk, expected, args.mode, version_code=version_code)
        (output / "INSTALLATION.txt").write_text(
            f"Android version code: {version_code}\nCertificate SHA-256: {expected}\n"
            "Install over the existing app only when package and signing certificate match.\n"
            "Physical-device update/save retention remains untested. Never uninstall or clear data.\n")


if __name__ == "__main__":
    main()
