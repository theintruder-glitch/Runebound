# Keep updating Runebound without losing progress

Every install-over-existing update must keep package `app.runebound.godot`, the same signing certificate/private key, and an accepted version code. Matching those is necessary; actual Android install/save retention still needs device validation. Never uninstall the installed game or clear its data to bypass a signature error.

The earlier automatically generated test keys were disposable and deleted after each CI run. Those APKs cannot form a continuing update series. An APK contains the public certificate, not the private key, so downloading an old APK cannot recover its signing key.

## Existing installed game

First use Pause → Export character save and keep the exported JSON separately. If available, also keep the original Godot project and APK.

Look for the signing keystore in the Godot export configuration / Editor Settings → Export → Android on the device or computer that made the installed APK, or in its private backups/CI secrets. Do not post the keystore/password in chat, issues or source control. An unknown key must be compared with the installed APK certificate before it is used for an update.

If it has the historical Runebound certificate (`79a1ef0f60f3b4c6e65bd42cc422b28c7e969dd5ae54b0ddc77242f9287bab37`), configure these private repository Actions secrets:

- ANDROID_DEBUG_KEYSTORE_BASE64 — base64-encoded existing keystore
- ANDROID_DEBUG_KEY_ALIAS — existing alias
- ANDROID_DEBUG_KEY_PASSWORD — existing password

If the installed app uses a different retained key, configure ANDROID_UPDATE_KEYSTORE_BASE64, ANDROID_UPDATE_KEY_ALIAS and ANDROID_UPDATE_KEY_PASSWORD, and the public Actions variable ANDROID_UPDATE_CERT_SHA256 with the matching certificate's 64-character SHA-256. Keep an offline backup of that same private key. Do not replace it between builds.

Settings page: https://github.com/theintruder-glitch/Runebound/settings/secrets/actions
Variables page: https://github.com/theintruder-glitch/Runebound/settings/variables/actions

This session's GitHub connection cannot write Actions secrets, so secure signing setup is still required. Do not put signing values in a workflow file.

## Builds from now on

PRs run import/tests only and publish diagnostics, never a disposable installable APK. Manual dispatch defaults to `original`; use `updates` only for the separately configured persistent certificate. Missing credentials or a mismatched certificate stop the build. No update key is generated automatically.

The existing workflow uses version code `1000 + github.run_number`. Keep using this workflow's numbering; do not reset it or publish a manual build with a lower code than the installed version. Locally, update builds require an explicit `--version-code` greater than the source baseline. The temporary export version override is restored even if export fails; the checked-in package/export preset and character saves remain unchanged.

After setup, download a verified update APK and tap it on the phone. Android should offer an update when the installed package/certificate/version are compatible. Cancel if it asks you to uninstall or rejects the signature. Verify the existing character after updating.

If the installed app's private key cannot be recovered, an in-place update signed by that key is blocked. Preserve the original installation and JSON backup. A one-time move into a separately installed, permanently signed series (for example in another Android profile) can use the game's existing character import; verify the imported character before considering any later migration. That does not retroactively make the old disposable APKs update-compatible.

## New continuing series prepared after the old installation was cleared

The public certificate for the new continuing series is pinned in android-update-certificate.sha256. The private key was generated once in the private execution workspace with alias runebound and a 10,000-day validity. It is not committed. Update mode now rejects any certificate other than this pinned series, even if a different certificate is entered in the repository variable. Original mode still requires the historical original certificate.

A private backup ZIP and the first version-code-1020 APK were prepared locally. Workspace storage alone is not a durable backup: download and keep the private ZIP safely, and configure the three ANDROID_UPDATE_* Actions secrets plus the public ANDROID_UPDATE_CERT_SHA256 variable from the matching text files in that ZIP. Never upload the ZIP or its private files to GitHub source, issues or public artifacts. The ZIP contains the key and password; protect it as a private signing credential. The current connector cannot complete this secret setup.

After setup, select updates mode for this new series; do not use original mode. Future workflow version codes will exceed 1020 as the existing workflow counter increases. The first local APK was independently checked; install-over-existing behavior still requires testing on the phone.
