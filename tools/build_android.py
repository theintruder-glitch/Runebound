#!/usr/bin/env python3
"""Import, test, export and verify Runebound without changing its export preset."""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile

from android_checks import ROOT, run_logged
from verify_android import ORIGINAL_CERT, verify


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=["fresh-install-only", "original"], default="fresh-install-only")
    args = parser.parse_args()
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
        key = temporary / "signing.keystore"
        if args.mode == "original":
            encoded = os.environ.get("ORIGINAL_KEYSTORE_B64")
            alias = os.environ.get("ORIGINAL_KEY_ALIAS")
            password = os.environ.get("ORIGINAL_KEY_PASSWORD")
            if not all([encoded, alias, password]):
                raise RuntimeError("Original signing key/alias/password unavailable; refusing to generate a replacement for an update")
            key.write_bytes(base64.b64decode(encoded, validate=True))
        else:
            alias = "androiddebugkey"
            password = "android"
            subprocess.run([str(java / "bin/keytool"), "-genkeypair", "-keystore", str(key),
                            "-storepass", password, "-keypass", password, "-alias", alias,
                            "-dname", "CN=Runebound FRESH INSTALL ONLY", "-keyalg", "RSA",
                            "-keysize", "2048", "-validity", "30"], check=True, capture_output=True)
        key.chmod(0o600)
        env.update(GODOT_ANDROID_KEYSTORE_DEBUG_PATH=str(key),
                   GODOT_ANDROID_KEYSTORE_DEBUG_USER=alias,
                   GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=password)
        cert = temporary / "certificate.der"
        subprocess.run([str(java / "bin/keytool"), "-exportcert", "-keystore", str(key),
                        "-alias", alias, "-storepass:env", "GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD",
                        "-file", str(cert)], env=env, check=True, capture_output=True)
        expected = hashlib.sha256(cert.read_bytes()).hexdigest()
        if args.mode == "original" and expected != ORIGINAL_CERT:
            raise RuntimeError("Supplied key differs from historical Runebound signing certificate; refusing update build")
        settings = temporary / "config/godot/editor_settings-4.5.tres"
        settings.parent.mkdir(parents=True)
        values = {"export/android/java_sdk_path": str(java),
                  "export/android/android_sdk_path": str(sdk),
                  "export/android/debug_keystore": str(key),
                  "export/android/shutdown_adb_on_exit": False}
        settings.write_text('[gd_resource type="EditorSettings" format=3]\n\n[resource]\n' +
                            "".join(f"{k} = {json.dumps(v)}\n" for k, v in values.items()))
        run_logged([engine, "--headless", "--path", str(ROOT), "--editor", "--import"], logs / "import.log", env)
        run_logged(["python3", str(ROOT / "tools/android_checks.py"), "--godot", engine,
                    "--logs", str(logs)], logs / "test-summary.log", env, timeout=600)
        apk = output / ("Runebound-Android-FRESH-INSTALL-ONLY.apk" if args.mode == "fresh-install-only"
                        else "Runebound-Android-original-certificate.apk")
        run_logged([engine, "--headless", "--path", str(ROOT), "--export-debug", "Android", str(apk)],
                   logs / "export.log", env, timeout=300)
        for name, content in original.items():
            if (ROOT / name).read_bytes() != content:
                raise RuntimeError(f"Build changed {name}")
        verify(apk, sdk, expected, args.mode)
        (output / "INSTALLATION.txt").write_text(
            "FRESH INSTALL ONLY: use a separate test device/profile without Runebound.\n"
            "This disposable certificate cannot update the original installed game.\n"
            "Never uninstall the existing game or clear its data to install this APK.\n"
            if args.mode == "fresh-install-only" else
            "Original historical certificate verified. Physical-device upgrade testing remains required.\n"
            "Keep character backups; never uninstall the game or clear its data.\n")


if __name__ == "__main__":
    main()
