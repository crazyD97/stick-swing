---
name: release
description: Prepare a Google Play release - bump the version, run tests and playtest, export the signed AAB, and walk the store checklist.
disable-model-invocation: true
argument-hint: "[version name, e.g. 1.0.0]"
---

# Release

Requested version: `$ARGUMENTS` (empty = bump the patch number).

1. Preconditions. Stop and tell the user if any fail:
   - git working tree clean (`git status`), on the branch they release from.
   - `tools/build.sh test` and `tools/build.sh lint` pass.
   - `/playtest` desktop pass is clean (run it now if it has not been run since the last change).
   - Ads in `addons/studio_core/services/ads.gd`: if the real plugin is wired, ask the user to confirm the **real** ad unit IDs
     are configured outside the repo; test IDs must never ship to production, real IDs must never be clicked in testing.
2. Bump the version: `node tools/version.mjs bump` or `node tools/version.mjs bump --name <X.Y.Z>`.
   The version code must be higher than every build already uploaded to Play.
3. The user must have set `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `_USER` and `_PASSWORD` in their own terminal.
   **Never** ask for, read, print or store the password or keystore. If the variables are missing, give them the commands from
   docs/SETUP.md "Release signing" and stop.
4. Build: `tools/build.sh aab` (PowerShell `.\tools\build.ps1 aab`). Output: `build/game-release.aab`.
5. Commit the version bump: `Release <X.Y.Z> (code <N>)` and tag `v<X.Y.Z>`. Push only if the user asks.
6. Walk the checklist with the user, ticking what is already done:
   - [ ] Upload the AAB to **Internal testing** first (no review), install from Play on a phone, smoke test
   - [ ] Store listing: 512×512 icon, 1024×500 feature graphic, at least 2 phone screenshots (`/playtest` screenshots
         are a start), short and full description
   - [ ] Content rating questionnaire, target audience (avoid under-13 at first), data safety form, privacy policy URL
   - [ ] Ads declaration and consent form (UMP) if ads are on
   - [ ] New personal account: closed test with 12+ testers opted in for 14 days in a row before production
   - [ ] Release notes for this version
7. Report the version, code, AAB path and size, and what is left on the checklist.
