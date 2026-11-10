---
name: run-on-phone
description: Export a debug APK, install it on the connected Android phone or emulator, launch it, and check the screenshot and logs.
disable-model-invocation: true
---

# Run on phone

1. Check a device is connected: `adb devices`. If none is listed (or it says `unauthorized`), stop and tell the user:
   plug in the phone with USB debugging on and accept the prompt, or start the emulator from Android Studio's Device Manager.
   With several devices, ask which one and export `ANDROID_SERIAL=<serial>` for the next commands.
2. Run `tools/build.sh phone` (PowerShell: `.\tools\build.ps1 phone`). It exports `build/game-debug.apk`, installs it,
   launches it, saves `build/phone.png` and `build/logcat.txt`, and fails if the log has errors.
   - "No export template found": templates missing or wrong version (docs/SETUP.md step 5). Tell the user; do not try to fix.
   - "Invalid Android SDK path": docs/SETUP.md step 4. Tell the user.
   - `INSTALL_FAILED_UPDATE_INCOMPATIBLE`: an older build with another signature is installed. Ask before running
     `adb uninstall <package>`: it deletes the player's save on that device.
3. Read `build/phone.png` and look at it. The game should be on the splash or main menu, not a black or white screen.
   A black screen usually means the renderer is not Compatibility.
4. Read `build/logcat.txt`. Report any `ERROR` / `SCRIPT ERROR` lines with the file and line they point at, then fix them
   in the code and repeat from step 2.
5. If the mobile MCP server is connected, you may also tap through the menu with it (`mobile_take_screenshot`,
   `mobile_click_on_screen_at_coordinates`). For a full pass use `/playtest`.
6. Report: device, package id, version, what the screenshot shows, and any errors.
