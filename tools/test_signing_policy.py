import unittest
from pathlib import Path
from signing_policy import signing_inputs, update_version
from verify_android import ORIGINAL_CERT

class SigningPolicyTests(unittest.TestCase):
    def test_missing_keys_fail_closed(self):
        for mode in ('original','updates'):
            with self.assertRaises(ValueError): signing_inputs(mode,{})
    def test_no_disposable_update_mode(self):
        with self.assertRaises(ValueError): signing_inputs('fresh-install-only',{})
    def test_original_certificate_is_fixed(self):
        env={f'ORIGINAL_{key}':'test-fixture' for key in ('KEYSTORE_B64','KEY_ALIAS','KEY_PASSWORD')}
        self.assertEqual(signing_inputs('original',env)[3],ORIGINAL_CERT)
    def test_updates_require_pinned_certificate(self):
        env={f'UPDATE_{key}':'test-fixture' for key in ('KEYSTORE_B64','KEY_ALIAS','KEY_PASSWORD')}
        with self.assertRaises(ValueError): signing_inputs('updates',env)
        env['UPDATE_CERT_SHA256']='ab'*32
        with self.assertRaises(ValueError): signing_inputs('updates',env)
        pinned=(Path(__file__).resolve().parents[1]/'android-update-certificate.sha256').read_text().strip()
        env['UPDATE_CERT_SHA256']=pinned
        self.assertEqual(signing_inputs('updates',env)[3],pinned)
    def test_version_must_increase(self):
        for value in (None,'19','18','-1','abc','2100000001'):
            with self.assertRaises(ValueError): update_version(value,19)
        self.assertEqual(update_version('1020',19),1020)
