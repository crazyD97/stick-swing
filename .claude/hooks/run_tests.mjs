// Stop hook: when Claude finishes, run the GUT tests if any game file changed since the last green run.
// Failures go back to Claude, which keeps working until they pass.
import { readdirSync, statSync, writeFileSync, mkdirSync } from "node:fs";
import path from "node:path";
import { readInput, run, godotBin, block, projectDir, existsSync } from "./_common.mjs";

const input = readInput();
if (input.stop_hook_active) process.exit(0); // already continuing because of this hook: do not loop

const marker = path.join(projectDir, ".godot", "last_green_tests");
const WATCH = ["game", "addons/studio_core", "tests", "assets", "project.godot"];
const EXT = /\.(gd|tscn|tres|godot)$/;

function newestMtime(p) {
  const abs = path.join(projectDir, p);
  if (!existsSync(abs)) return 0;
  const st = statSync(abs);
  if (!st.isDirectory()) return EXT.test(p) ? st.mtimeMs : 0;
  let newest = 0;
  for (const name of readdirSync(abs)) newest = Math.max(newest, newestMtime(path.join(p, name)));
  return newest;
}

const lastGreen = existsSync(marker) ? statSync(marker).mtimeMs : 0;
if (WATCH.every((p) => newestMtime(p) <= lastGreen)) process.exit(0);

const godot = godotBin();
const probe = run(godot, ["--version"], { timeout: 30000 });
if (probe.missing || !probe.ok) {
  process.stderr.write(`Godot not found (${godot}); skipping tests. Set GODOT or put godot on PATH.\n`);
  process.exit(0);
}

run(godot, ["--headless", "--path", ".", "--import"], { timeout: 300000 });
const res = run(godot, ["--headless", "--path", ".", "-s", "addons/gut/gut_cmdln.gd", "-gexit"], { timeout: 600000 });
const clean = res.out.replace(/\x1b\[[0-9;]*m/g, "");
if (!res.ok) {
  const summary = clean.split("\n").filter((l) => /^\s*- test_|^res:\/\/tests|Failed|SCRIPT ERROR|Parse Error|Unexpected|Passing|Failing/i.test(l));
  block(`GUT tests failed. Fix the code (never the test, unless the test is wrong) and finish again:\n${summary.slice(-60).join("\n")}`);
}
mkdirSync(path.dirname(marker), { recursive: true });
writeFileSync(marker, new Date().toISOString());
process.exit(0);
