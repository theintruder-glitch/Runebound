# GitHub development handoff — 0.17.0

This branch continues the supplied v0.15.0 source, v0.16.0 stabilization and the Focused Combat update. Android is primary; Windows shares combat and spell logic. The older repository main snapshot is v0.12.0 until the review branch is merged.

New work: touch selection/drag/CAST/CANCEL for learned ground spells; independent movement/aim fingers; shared forward melee; animated misses, sweeps, recoil and casting glow; guarded ordinary-enemy stagger; lifecycle and mana checks. Existing progression, Survival, fishing/crafting and save handling are retained.

Read README.md, VERIFICATION.md and PLAYTEST.md. Source and exact Android resources pass 1,628 checks; Windows PCK passes 333. Build verification checks actual signer blocks and final byte identity. The old v0.16 APK copy fails fresh signature verification; use the verified v0.17 output.

No keys, passwords, player saves or binaries are committed. CI tests and Windows export run automatically; remote Android release exports require the original signing secrets. Do not generate a replacement identity.
