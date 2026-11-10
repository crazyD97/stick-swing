#!/usr/bin/env node
// Start a new game from this template: copy it, then set name, package id, orientation and icon colour.
//
//   node tools/new_game.mjs --name "Stick Run" --dir ../stick-run
//   node tools/new_game.mjs --name "Stick Run" --in-place           # after GitHub "Use this template"
//
// Options:
//   --name "Title"            app name shown on the phone and in the menu (required)
//   --package com.x.y         Android package id (default: com.droidpark.<name without spaces>)
//   --dir PATH                copy the template to PATH (must not exist or be empty)
//   --in-place                rename this checkout instead of copying
//   --orientation portrait|landscape   (default portrait)
//   --icon FILE.svg|FILE.png  use this icon instead of a recoloured default
//   --no-git                  do not git init/commit the new folder
import { cpSync, existsSync, readdirSync, readFileSync, writeFileSync, copyFileSync, rmSync } from "node:fs";
import { spawnSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const templateRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const SKIP = new Set([".git", ".godot", "build", "android", "node_modules"]);
const PACKAGE_RE = /^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$/;

export function slugify(name) {
  return name.toLowerCase().replace(/[^a-z0-9]+/g, "");
}

export function defaultPackage(name) {
  let slug = slugify(name);
  if (!slug || /^[0-9]/.test(slug)) slug = "game" + slug;
  return `com.droidpark.${slug}`;
}

/** Deterministic, pleasant icon colour from the name. */
export function colourFor(name) {
  let h = 0;
  for (const ch of name) h = (h * 31 + ch.codePointAt(0)) % 360;
  const [r, g, b] = hslToRgb(h / 360, 0.65, 0.5);
  return "#" + [r, g, b].map((v) => v.toString(16).padStart(2, "0")).join("");
}

function hslToRgb(h, s, l) {
  const f = (n) => {
    const k = (n + h * 12) % 12;
    const a = s * Math.min(l, 1 - l);
    return Math.round(255 * (l - a * Math.max(-1, Math.min(k - 3, 9 - k, 1))));
  };
  return [f(0), f(8), f(4)];
}

export function renameProject(text, { name, orientation }) {
  let out = text
    .replace(/^config\/name="[^"]*"/m, `config/name="${name.replace(/"/g, '\\"')}"`)
    .replace(/^config\/version="[^"]*"/m, 'config/version="0.1.0"');
  const landscape = orientation === "landscape";
  out = out
    .replace(/^window\/size\/viewport_width=\d+/m, `window/size/viewport_width=${landscape ? 1920 : 1080}`)
    .replace(/^window\/size\/viewport_height=\d+/m, `window/size/viewport_height=${landscape ? 1080 : 1920}`)
    .replace(/^window\/size\/window_width_override=\d+/m, `window/size/window_width_override=${landscape ? 960 : 540}`)
    .replace(/^window\/size\/window_height_override=\d+/m, `window/size/window_height_override=${landscape ? 540 : 960}`)
    .replace(/^window\/handheld\/orientation=\d+/m, `window/handheld/orientation=${landscape ? 0 : 1}`);
  return out;
}

export function renamePresets(text, { name, pkg }) {
  return text
    .replace(/^package\/unique_name="[^"]*"/gm, `package/unique_name="${pkg}"`)
    .replace(/^package\/name="[^"]*"/gm, `package/name="${name.replace(/"/g, '\\"')}"`)
    .replace(/^version\/code=\d+/gm, "version/code=1")
    .replace(/^version\/name="[^"]*"/gm, 'version/name="0.1.0"');
}

function parseArgs(argv) {
  const opts = { orientation: "portrait", git: true };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const next = () => argv[++i];
    if (a === "--name") opts.name = next();
    else if (a === "--package") opts.pkg = next();
    else if (a === "--dir") opts.dir = next();
    else if (a === "--in-place") opts.inPlace = true;
    else if (a === "--orientation") opts.orientation = next();
    else if (a === "--icon") opts.icon = next();
    else if (a === "--no-git") opts.git = false;
    else fail(`unknown option ${a}`);
  }
  return opts;
}

function fail(msg) {
  console.error(`new_game: ${msg}\nSee the header of tools/new_game.mjs for usage.`);
  process.exit(1);
}

function edit(file, fn) {
  writeFileSync(file, fn(readFileSync(file, "utf8")));
}

function main(argv) {
  const opts = parseArgs(argv);
  if (!opts.name) fail("--name is required");
  if (!!opts.dir === !!opts.inPlace) fail("give exactly one of --dir PATH or --in-place");
  if (!["portrait", "landscape"].includes(opts.orientation)) fail("--orientation must be portrait or landscape");
  const pkg = opts.pkg || defaultPackage(opts.name);
  if (!PACKAGE_RE.test(pkg)) fail(`invalid package id "${pkg}" (lowercase, dots, e.g. com.studio.game)`);
  if (opts.icon && !existsSync(opts.icon)) fail(`icon not found: ${opts.icon}`);

  let target = templateRoot;
  if (opts.dir) {
    target = path.resolve(opts.dir);
    if (existsSync(target) && readdirSync(target).length > 0) fail(`${target} already exists and is not empty`);
    cpSync(templateRoot, target, {
      recursive: true,
      filter: (src) => !SKIP.has(path.basename(src)) || path.dirname(src) !== templateRoot,
    });
  }

  edit(path.join(target, "project.godot"), (t) => renameProject(t, { name: opts.name, orientation: opts.orientation }));
  edit(path.join(target, "export_presets.cfg"), (t) => renamePresets(t, { name: opts.name, pkg }));

  if (opts.icon) {
    const ext = path.extname(opts.icon).toLowerCase();
    if (ext !== ".svg" && ext !== ".png") fail("--icon must be .svg or .png");
    copyFileSync(opts.icon, path.join(target, "icon" + ext));
    if (ext === ".png") {
      rmSync(path.join(target, "icon.svg"), { force: true });
      rmSync(path.join(target, "icon.svg.import"), { force: true });
      edit(path.join(target, "project.godot"), (t) => t.replace('config/icon="res://icon.svg"', 'config/icon="res://icon.png"'));
    }
  } else {
    edit(path.join(target, "icon.svg"), (t) => t.replace(/fill="#2b6cff"/, `fill="${colourFor(opts.name)}"`));
  }

  edit(
    path.join(target, "README.md"),
    () =>
      `# ${opts.name}\n\nA 2D Android game made from the DroidPark template.\n\n` +
      `- Package id: \`${pkg}\`\n- Orientation: ${opts.orientation}\n\n` +
      "Read `CLAUDE.md` for how the project is organised and `docs/SETUP.md` for machine setup.\n\n" +
      "```powershell\n.\\tools\\build.ps1 test\n.\\tools\\build.ps1 run\n.\\tools\\build.ps1 phone\n```\n",
  );

  if (opts.dir && opts.git) {
    const git = (...args) => spawnSync("git", args, { cwd: target, encoding: "utf8" });
    if (git("init", "-q").status === 0) {
      git("add", "-A");
      const commit = git("commit", "-q", "-m", `Start ${opts.name} from the DroidPark template`);
      if (commit.status !== 0) console.warn("git commit skipped (set git user.name/user.email); files are staged.");
    }
  }

  console.log(`Created "${opts.name}" (${pkg}, ${opts.orientation}) in ${target}`);
  console.log("Next: open it in Godot once (or run tools/build test), then tools/build phone.");
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main(process.argv.slice(2));
}
