"""Fail-closed signing and version policy; never generate an update key."""
import re
from pathlib import Path
from verify_android import ORIGINAL_CERT


def signing_inputs(mode, environment):
    if mode not in ('original', 'updates'):
        raise ValueError('Installable builds require original or updates signing mode')
    prefix = 'ORIGINAL' if mode == 'original' else 'UPDATE'
    values = [environment.get(prefix + name, '') for name in
              ('_KEYSTORE_B64', '_KEY_ALIAS', '_KEY_PASSWORD')]
    certificate = ORIGINAL_CERT if mode == 'original' else environment.get('UPDATE_CERT_SHA256', '').lower()
    if not all(values) or not re.fullmatch('[0-9a-f]{64}', certificate):
        raise ValueError('Persistent signing key, alias, password and pinned certificate are required. No replacement key will be generated.')
    if mode == "updates":
        pinned = (Path(__file__).resolve().parents[1] / "android-update-certificate.sha256").read_text().strip()
        if certificate != pinned:
            raise ValueError("Update signing certificate differs from the pinned series; refusing identity change")
    return (*values, certificate)


def update_version(value, baseline):
    if not value or not re.fullmatch('[0-9]+', value):
        raise ValueError('An explicit increasing Android version code is required')
    code = int(value)
    if not baseline < code <= 2100000000:
        raise ValueError('Update version code must exceed the source baseline and fit Android limits')
    return code
