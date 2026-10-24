# GitHub development handoff — 0.16.0

This branch advances the repository from its older v0.12.0 snapshot using the user-supplied v0.15.0 source, then adds the Shelter & Steel stabilization milestone. Android remains primary; Windows uses the same gameplay scripts.

Read README.md, VERIFICATION.md, PLAYTEST.md and ROADMAP_ANDROID.md. New tests are in tests/test_stability.gd. The reproducible runner is tools/run_tests.py. The obsolete debug workflow is superseded by .github/workflows/build.yml.

No signing keys, passwords, build binaries or player saves are committed. The new workflow requires original release-signing secrets for manually requested Android exports; automatic PR checks and Windows builds do not need a key. Local build verification is recorded separately from remote CI and physical-device results.
