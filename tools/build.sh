#!/usr/bin/env bash
# One entry point for every routine task. Mac/Linux/CI twin of tools/build.ps1.
#
#   tools/build.sh test            import + run all GUT tests headless
#   tools/build.sh lint            gdlint + gdformat --check
#   tools/build.sh format          gdformat (rewrites files)
#   tools/build.sh run [scene]     play on desktop in a phone-shaped window
#   tools/build.sh shot [scene] [seconds] [out.png]   screenshot then quit
#   tools/build.sh apk             export debug APK (build/game-debug.apk)
#   tools/build.sh phone           apk + adb install + launch + screenshot + logs (build/phone.png, build/logcat.txt)
#   tools/build.sh playtest        journey test + screenshots of every screen into build/playtest/
#   tools/build.sh aab             export signed release AAB (needs keystore env vars)
#   tools/build.sh logcat          stream Godot logs from the phone
#
#   tools/build.sh version [bump]  show or bump the version (see tools/version.mjs)
#
# Env: GODOT (path to the Godot 4.7 binary, default "godot"), ADB (default "adb").
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"
ADB="${ADB:-adb}"
GDFORMAT_ARGS=(--line-length 120)
LINT_DIRS=(addons/studio_core game tests)

package_name() {
  grep -m1 '^package/unique_name=' export_presets.cfg | cut -d'"' -f2
}

import() {
  "$GODOT" --headless --path . --import >/dev/null 2>&1 || true
}

cmd="${1:-help}"
shift || true

case "$cmd" in
  test)
    import
    "$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gexit "$@"
    ;;
  lint)
    gdlint "${LINT_DIRS[@]}"
    gdformat "${GDFORMAT_ARGS[@]}" --check "${LINT_DIRS[@]}"
    ;;
  format)
    gdformat "${GDFORMAT_ARGS[@]}" "${LINT_DIRS[@]}"
    ;;
  run)
    args=()
    [[ -n "${1:-}" ]] && args=(-- "--scene=$1")
    "$GODOT" --path . "${args[@]}"
    ;;
  shot)
    scene="${1:-}"; secs="${2:-3}"; out="${3:-build/shot.png}"
    mkdir -p build
    args=(--shot="$secs" --shot-path="$out")
    [[ -n "$scene" ]] && args+=(--scene="$scene")
    "$GODOT" --path . -- "${args[@]}"
    ;;
  apk)
    mkdir -p build
    import
    "$GODOT" --headless --path . --export-debug "Android Debug" build/game-debug.apk
    ;;
  phone)
    "$0" apk
    pkg="$(package_name)"
    "$ADB" install -r build/game-debug.apk
    "$ADB" logcat -c || true
    "$ADB" shell monkey -p "$pkg" -c android.intent.category.LAUNCHER 1 >/dev/null
    sleep 6
    "$ADB" exec-out screencap -p > build/phone.png
    "$ADB" logcat -d -s godot:V GodotApp:V > build/logcat.txt || true
    echo "Launched $pkg; screenshot at build/phone.png, logs at build/logcat.txt"
    if grep -E "SCRIPT ERROR|ERROR:" build/logcat.txt; then
      echo "Errors found in the device log (above)." >&2
      exit 1
    fi
    ;;
  aab)
    : "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:?set GODOT_ANDROID_KEYSTORE_RELEASE_PATH (see docs/SETUP.md)}"
    : "${GODOT_ANDROID_KEYSTORE_RELEASE_USER:?set GODOT_ANDROID_KEYSTORE_RELEASE_USER}"
    : "${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:?set GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD}"
    mkdir -p build
    import
    "$0" test
    extra=()
    [[ -d android/build ]] || extra=(--install-android-build-template)
    "$GODOT" --headless --path . "${extra[@]}" --export-release "Android Release" build/game-release.aab
    ;;
  playtest)
    out=build/playtest
    rm -rf "$out"; mkdir -p "$out"
    import
    "$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gexit -gdir=res://tests/integration
    shot() { "$GODOT" --path . -- --temp-save "$@" >/dev/null 2>&1 || echo "shot failed: $*" >&2; }
    shot --shot=0.8 --shot-path="$out/1_splash.png"
    shot --scene=res://game/ui/main_menu.tscn --shot=1 --shot-path="$out/2_menu.png"
    shot --scene=res://game/levels/level_01.tscn --tap-at=0.5,2.4 --shot=3 --shot-path="$out/3_level_running.png"
    shot --scene=res://game/levels/level_01.tscn --tap-at=0.5 --shot=5.6 --shot-path="$out/4_game_over.png"
    shot --scene=res://game/ui/level_select.tscn --shot=1 --shot-path="$out/5_level_select.png"
    shot --scene=res://game/ui/settings.tscn --shot=1 --shot-path="$out/6_settings.png"
    ls "$out"
    ;;
  version)
    node tools/version.mjs "$@"
    ;;
  logcat)
    "$ADB" logcat -s godot:V GodotApp:V
    ;;
  *)
    sed -n '2,19p' "$0"
    ;;
esac
