#!/usr/bin/env python3
"""Verify an APK against the Android preset and a known signing certificate."""
import argparse
import configparser
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ORIGINAL_CERT = "79a1ef0f60f3b4c6e65bd42cc422b28c7e969dd5ae54b0ddc77242f9287bab37"


def verify(apk, sdk, expected_cert, mode):
    def run(binary, *args):
        return subprocess.check_output([str(sdk / "build-tools/35.0.0" / binary),
                                        *args, str(apk)], text=True)

    config = configparser.ConfigParser(interpolation=None)
    config.read(ROOT / "export_presets.cfg")
    options = config["preset.0.options"]
    with zipfile.ZipFile(apk) as archive:
        if archive.testzip():
            raise RuntimeError("APK ZIP integrity failed")
        names = archive.namelist()
        abis = {n.split("/")[1] for n in names if n.startswith("lib/") and n.endswith(".so")}
        if abis != {"arm64-v8a"} or "lib/arm64-v8a/libgodot_android.so" not in names:
            raise RuntimeError(f"Wrong native libraries: {abis}")
        for required in ["AndroidManifest.xml", "classes.dex", "assets/project.binary",
                         "assets/scripts/game.gdc", "assets/scripts/hud.gdc",
                         "assets/scripts/survival.gdc", "assets/scripts/farming.gdc"]:
            if required not in names:
                raise RuntimeError(f"APK missing {required}")
        if any(n.startswith(("assets/tests/", "assets/tools/", "assets/signing/")) for n in names):
            raise RuntimeError("Development files leaked into APK")
    badging = run("aapt", "dump", "badging")
    package = re.search(r"^package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'", badging, re.M)
    expected = ("app.runebound.godot", options["version/code"], json.loads(options["version/name"]))
    if not package or package.groups() != expected:
        raise RuntimeError(f"Package/version mismatch: expected {expected}")
    if "sdkVersion:'24'" not in badging or "targetSdkVersion:'35'" not in badging:
        raise RuntimeError("Expected minimum API 24 and target API 35")
    if "launchable-activity:" not in badging or "uses-permission:" in badging:
        raise RuntimeError("Unexpected activity or permissions in offline Android game")
    signing = run("apksigner", "verify", "--verbose", "--print-certs")
    certificates = re.findall(r"Signer #\d+ certificate SHA-256 digest: ([0-9a-f]+)", signing)
    if certificates != [expected_cert.lower()] or "Verified using v2 scheme (APK Signature Scheme v2): true" not in signing:
        raise RuntimeError("APK signing certificate or v2 signature mismatch")
    if mode == "original" and expected_cert.lower() != ORIGINAL_CERT:
        raise RuntimeError("Original signing identity does not match historical Runebound certificate")
    run("zipalign", "-c", "-P", "16", "4")
    checksum = hashlib.sha256(apk.read_bytes()).hexdigest()
    report = {"apk": apk.name, "sha256": checksum, "package": expected[0],
              "versionCode": int(expected[1]), "versionName": expected[2],
              "minSdk": 24, "targetSdk": 35, "abis": sorted(abis),
              "certificate_sha256": certificates[0], "signing_mode": mode,
              "zip_integrity": True, "signature_verified": True, "alignment_16kb": True,
              "physical_device_tested": False,
              "installation": "Original certificate verified; device upgrade still untested" if mode == "original"
              else "FRESH INSTALL ONLY on a separate test device/profile; never uninstall an existing game"}
    apk.with_suffix(".verification.json").write_text(json.dumps(report, indent=2) + "\n")
    apk.with_suffix(".apk.sha256").write_text(f"{checksum}  {apk.name}\n")
    apk.with_suffix(".badging.txt").write_text(badging)
    apk.with_suffix(".signing.txt").write_text(signing)
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path)
    parser.add_argument("--sdk", type=Path, default=os.environ.get("ANDROID_HOME"), required=not os.environ.get("ANDROID_HOME"))
    parser.add_argument("--certificate", required=True)
    parser.add_argument("--mode", choices=["fresh-install-only", "original"], required=True)
    args = parser.parse_args()
    verify(args.apk, args.sdk, args.certificate, args.mode)
