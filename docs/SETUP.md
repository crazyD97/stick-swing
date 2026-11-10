# Machine setup (Phase 1)

You do this once on your PC; after that it serves every game. It takes about an hour, mostly downloads.
These steps are for Windows. On Mac or Linux only the installers and paths change.

## 1. Install the tools

Open **PowerShell** and run:

```powershell
winget install Git.Git
winget install OpenJS.NodeJS.LTS
winget install Microsoft.OpenJDK.17
winget install Google.AndroidStudio
winget install Python.Python.3.12
winget install Anthropic.ClaudeCode
```

Install Git first: Claude Code uses Git's bash on Windows.

Then:

1. Download **Godot 4.7.1 standard** (not .NET) from https://godotengine.org/download/archive/4.7.1-stable/.
2. Unzip it to `C:\tools\godot\` and rename the exe to `godot.exe`. Keep the console exe as `godot_console.exe`
   if you want to see logs in a terminal.
3. Add `C:\tools\godot` to your PATH (Start → "Edit the system environment variables" → Environment Variables → Path).
4. Install the GDScript linter: `pip install "gdtoolkit==4.*"`.

Check everything from a **new** terminal:

```powershell
git --version; node --version; java -version; godot --version; gdlint --version
```

## 2. Android SDK

Open Android Studio → **More Actions → SDK Manager**:

- **SDK Platforms**: Android 15 (API 35) and Android 16 (API 36)
- **SDK Tools** (tick "Show Package Details"): Android SDK Platform-Tools, Build-Tools **35.0.1**,
  Command-line Tools (latest), CMake **3.10.2.4988404**, NDK **28.1.13356709**

Add `%LOCALAPPDATA%\Android\Sdk\platform-tools` to your PATH so `adb` works everywhere.

## 3. Emulator

Android Studio → **Device Manager → Create device** → Pixel 8 → system image Android 16 (API 36, x86_64).

## 4. Point Godot at Java and the SDK

Open the project in Godot (`godot -e --path <this folder>`). Then go to **Editor → Editor Settings → Export → Android**:

- Java SDK Path: the JDK 17 folder, e.g. `C:\Program Files\Microsoft\jdk-17...`
- Android SDK Path: `C:\Users\<you>\AppData\Local\Android\Sdk`

Godot creates a debug keystore by itself the first time you export.

## 5. Export templates

In Godot: **Editor → Manage Export Templates → Download and Install**. The templates must match the editor version
exactly (4.7.1). A mismatch is the most common cause of failing exports.

## 6. Phone

On the phone: Settings → About phone → tap **Build number** 7 times → Developer options → **USB debugging** on.
Plug it in, accept the prompt, then check:

```powershell
adb devices
```

## 7. Claude Code

```powershell
cd <this folder>
claude
```

Follow the login prompt. Claude reads `CLAUDE.md` automatically and loads the project's skills, hooks and
MCP servers from `.claude/` and `.mcp.json`. The first time, Claude Code asks you to trust the folder: say yes.

Inside Claude Code, type `/mcp`. Both `godot` and `mobile` should show as **connected**. The first start downloads
them with npx, so give it a minute.

- `.mcp.json` is written for **Windows** (`cmd /c npx ...`). On Mac or Linux, change each server's `"command": "cmd"`
  to `"command": "npx"` and drop `"/c", "npx"` from its args.
- godot-mcp finds `godot` on your PATH. If you keep Godot elsewhere, set a `GODOT` user environment variable to the
  full path of `godot.exe`; the build scripts and hooks use it too.
- The hooks need Node.js (step 1) and gdtoolkit (`gdlint`, `gdformat`) on PATH.

Type `/` to see the project skills: `/new-game`, `/add-level`, `/add-character`, `/run-on-phone`, `/playtest`, `/release`.

## Phase 1 done check

```powershell
.\tools\build.ps1 test     # 25+ tests pass
.\tools\build.ps1 run      # game opens in a phone-shaped window
.\tools\build.ps1 phone    # game installs and launches on your phone
```

When `phone` puts the game on your phone, Phase 1 is done.

## Phase 3 done check (inside Claude Code)

```text
/new-game "Test Game"        -> creates ../test-game with a new name and package id
```

Open `../test-game` in Claude Code, then:

```text
/run-on-phone                -> "Test Game" opens on your phone
```

## Release signing (only needed for Phase 4)

Create one keystore and keep it **outside** the repo. Back it up in two places, with its password.

```powershell
keytool -genkey -v -keystore C:\keys\droidpark-release.keystore -alias droidpark -keyalg RSA -keysize 2048 -validity 10000
```

Before `.\tools\build.ps1 aab`, set these for the session (or as user environment variables):

```powershell
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = "C:\keys\droidpark-release.keystore"
$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = "droidpark"
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = "<your password>"
```

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| Black screen on the phone | Renderer must be Compatibility (it is, in `project.godot`) |
| Export greyed out / "No export template found" | Step 5, same version as the editor |
| "Invalid Android SDK path" | Step 4; the SDK folder must contain `platform-tools` and `build-tools` |
| `adb devices` shows "unauthorized" | Unlock the phone and accept the USB debugging prompt |
| "Identifier X not declared" after adding a script | Run `godot --headless --path . --import` (the `test` command does it) |
