# One entry point for every routine task (Windows). Twin of tools/build.sh.
#
#   .\tools\build.ps1 test            import + run all GUT tests headless
#   .\tools\build.ps1 lint            gdlint + gdformat --check
#   .\tools\build.ps1 format          gdformat (rewrites files)
#   .\tools\build.ps1 run [scene]     play on desktop in a phone-shaped window
#   .\tools\build.ps1 shot [scene] [seconds] [out.png]   screenshot then quit
#   .\tools\build.ps1 apk             export debug APK (build\game-debug.apk)
#   .\tools\build.ps1 phone           apk + adb install + launch + screenshot + logs (build\phone.png, build\logcat.txt)
#   .\tools\build.ps1 playtest        journey test + screenshots of every screen into build\playtest\
#   .\tools\build.ps1 aab             export signed release AAB (needs keystore env vars)
#   .\tools\build.ps1 logcat          stream Godot logs from the phone
#
#   .\tools\build.ps1 version [bump]  show or bump the version (see tools/version.mjs)
#
# Env: GODOT (path to godot.exe, default "godot"), ADB (default "adb").
param(
    [Parameter(Position = 0)][string]$Command = "help",
    [Parameter(Position = 1, ValueFromRemainingArguments = $true)][string[]]$Rest
)
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

$Godot = if ($env:GODOT) { $env:GODOT } else { "godot" }
$Adb = if ($env:ADB) { $env:ADB } else { "adb" }
$LintDirs = @("addons/studio_core", "game", "tests")

function Invoke-Checked([string]$Exe, [string[]]$ArgList) {
    & $Exe @ArgList
    if ($LASTEXITCODE -ne 0) { throw "$Exe failed with exit code $LASTEXITCODE" }
}

function Import-Project {
    & $Godot --headless --path . --import *> $null
}

function Get-PackageName {
    $line = Select-String -Path export_presets.cfg -Pattern '^package/unique_name="(.+)"' | Select-Object -First 1
    return $line.Matches[0].Groups[1].Value
}

function Require-Env([string]$Name) {
    if (-not [Environment]::GetEnvironmentVariable($Name)) { throw "Set $Name first (see docs/SETUP.md)" }
}

$arg1 = if ($Rest.Count -ge 1) { $Rest[0] } else { "" }
$arg2 = if ($Rest.Count -ge 2) { $Rest[1] } else { "3" }
$arg3 = if ($Rest.Count -ge 3) { $Rest[2] } else { "build/shot.png" }

switch ($Command) {
    "test" {
        Import-Project
        Invoke-Checked $Godot (@("--headless", "--path", ".", "-s", "addons/gut/gut_cmdln.gd", "-gexit") + $Rest)
    }
    "lint" {
        Invoke-Checked "gdlint" $LintDirs
        Invoke-Checked "gdformat" (@("--line-length", "120", "--check") + $LintDirs)
    }
    "format" { Invoke-Checked "gdformat" (@("--line-length", "120") + $LintDirs) }
    "run" {
        $a = @("--path", ".")
        if ($arg1) { $a += @("--", "--scene=$arg1") }
        & $Godot @a
    }
    "shot" {
        New-Item -ItemType Directory -Force build | Out-Null
        $a = @("--path", ".", "--", "--shot=$arg2", "--shot-path=$arg3")
        if ($arg1) { $a += "--scene=$arg1" }
        Invoke-Checked $Godot $a
    }
    "apk" {
        New-Item -ItemType Directory -Force build | Out-Null
        Import-Project
        Invoke-Checked $Godot @("--headless", "--path", ".", "--export-debug", "Android Debug", "build/game-debug.apk")
    }
    "phone" {
        & $PSCommandPath apk
        if ($LASTEXITCODE -ne 0) { throw "APK export failed." }
        $pkg = Get-PackageName
        Invoke-Checked $Adb @("install", "-r", "build/game-debug.apk")
        & $Adb logcat -c
        & $Adb shell monkey -p $pkg -c android.intent.category.LAUNCHER 1 | Out-Null
        Start-Sleep -Seconds 6
        & $Adb shell screencap -p /sdcard/droidpark_shot.png
        & $Adb pull /sdcard/droidpark_shot.png build/phone.png | Out-Null
        & $Adb logcat -d -s godot:V GodotApp:V | Out-File -Encoding utf8 build/logcat.txt
        Write-Host "Launched $pkg; screenshot at build/phone.png, logs at build/logcat.txt"
        $errors = Select-String -Path build/logcat.txt -Pattern "SCRIPT ERROR|ERROR:"
        if ($errors) { $errors | ForEach-Object { Write-Host $_.Line }; throw "Errors found in the device log (above)." }
    }
    "aab" {
        Require-Env "GODOT_ANDROID_KEYSTORE_RELEASE_PATH"
        Require-Env "GODOT_ANDROID_KEYSTORE_RELEASE_USER"
        Require-Env "GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD"
        New-Item -ItemType Directory -Force build | Out-Null
        Import-Project
        & $PSCommandPath test
        if ($LASTEXITCODE -ne 0) { throw "Tests failed; not building a release." }
        $a = @("--headless", "--path", ".")
        if (-not (Test-Path android/build)) { $a += "--install-android-build-template" }
        Invoke-Checked $Godot ($a + @("--export-release", "Android Release", "build/game-release.aab"))
    }
    "playtest" {
        $out = "build/playtest"
        if (Test-Path $out) { Remove-Item -Recurse -Force $out }
        New-Item -ItemType Directory -Force $out | Out-Null
        Import-Project
        Invoke-Checked $Godot @("--headless", "--path", ".", "-s", "addons/gut/gut_cmdln.gd", "-gexit", "-gdir=res://tests/integration")
        $shots = @(
            @("--shot=0.8", "--shot-path=$out/1_splash.png"),
            @("--scene=res://game/ui/main_menu.tscn", "--shot=1", "--shot-path=$out/2_menu.png"),
            @("--scene=res://game/swing/swing_game.tscn", "--tap-at=0.4", "--hold=0.6-1.3", "--shot=1.15", "--shot-path=$out/3_swinging.png"),
            @("--scene=res://game/swing/swing_game.tscn", "--tap-at=0.4", "--shot=4.5", "--shot-path=$out/4_game_over.png"),
            @("--scene=res://game/swing/swing_game.tscn", "--shot=1", "--shot-path=$out/5_ready.png"),
            @("--scene=res://game/ui/settings.tscn", "--shot=1", "--shot-path=$out/6_settings.png")
        )
        foreach ($s in $shots) { & $Godot @(@("--path", ".", "--", "--temp-save") + $s) *> $null }
        Get-ChildItem $out | ForEach-Object { $_.Name }
    }
    "version" { & node tools/version.mjs @Rest }
    "logcat" { & $Adb logcat -s godot:V GodotApp:V }
    default { Get-Content $PSCommandPath | Select-Object -Skip 1 -First 15 }
}
