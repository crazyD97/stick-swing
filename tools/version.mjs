#!/usr/bin/env node
// Show or bump the game version. Keeps project.godot and both Android presets in sync.
//
//   node tools/version.mjs show
//   node tools/version.mjs bump                 # code +1, patch +1   (0.1.0 -> 0.1.1)
//   node tools/version.mjs bump --name 1.0.0    # code +1, name set explicitly
//
// Google Play rejects an upload whose version code is not higher than the last one.
import { readFileSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const PRESETS = path.join(root, "export_presets.cfg");
const PROJECT = path.join(root, "project.godot");

export function readVersion(presetsText) {
  const code = Number((presetsText.match(/^version\/code=(\d+)/m) || [])[1] || 1);
  const name = (presetsText.match(/^version\/name="([^"]*)"/m) || [])[1] || "0.1.0";
  return { code, name };
}

export function bumpPatch(name) {
  const parts = name.split(".").map((n) => Number.parseInt(n, 10) || 0);
  while (parts.length < 3) parts.push(0);
  parts[2] += 1;
  return parts.join(".");
}

export function applyVersion(presetsText, projectText, { code, name }) {
  return {
    presets: presetsText
      .replace(/^version\/code=\d+/gm, `version/code=${code}`)
      .replace(/^version\/name="[^"]*"/gm, `version/name="${name}"`),
    project: projectText.replace(/^config\/version="[^"]*"/m, `config/version="${name}"`),
  };
}

function main(argv) {
  const [cmd = "show", ...rest] = argv;
  const presets = readFileSync(PRESETS, "utf8");
  const current = readVersion(presets);
  if (cmd === "show") {
    console.log(`version ${current.name} (code ${current.code})`);
    return;
  }
  if (cmd !== "bump") {
    console.error("usage: node tools/version.mjs show | bump [--name X.Y.Z]");
    process.exit(1);
  }
  const nameIdx = rest.indexOf("--name");
  const name = nameIdx >= 0 ? rest[nameIdx + 1] : bumpPatch(current.name);
  if (!/^\d+\.\d+\.\d+$/.test(name || "")) {
    console.error(`invalid version name: ${name}`);
    process.exit(1);
  }
  const next = { code: current.code + 1, name };
  const out = applyVersion(presets, readFileSync(PROJECT, "utf8"), next);
  writeFileSync(PRESETS, out.presets);
  writeFileSync(PROJECT, out.project);
  console.log(`version ${current.name} (code ${current.code}) -> ${next.name} (code ${next.code})`);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main(process.argv.slice(2));
}
