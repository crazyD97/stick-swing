// Shared helpers for the project hooks. Hooks get a JSON payload on stdin.
// Exit code 2 = block / report back to Claude (stderr is shown to it). Exit 0 = fine.
import { spawnSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import path from "node:path";

export const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();

export function readInput() {
  try {
    return JSON.parse(readFileSync(0, "utf8") || "{}");
  } catch {
    return {};
  }
}

/** Path relative to the project, with forward slashes. Empty string if outside the project. */
export function relPath(filePath) {
  if (!filePath) return "";
  const abs = path.resolve(projectDir, filePath);
  const rel = path.relative(projectDir, abs);
  if (rel.startsWith("..") || path.isAbsolute(rel)) return "";
  return rel.split(path.sep).join("/");
}

/** Runs a program without a shell. Returns {ok, code, out, missing}. */
export function run(cmd, args, opts = {}) {
  const res = spawnSync(cmd, args, { cwd: projectDir, encoding: "utf8", timeout: opts.timeout ?? 120000 });
  if (res.error && res.error.code === "ENOENT") return { ok: false, code: -1, out: "", missing: true };
  const out = `${res.stdout ?? ""}${res.stderr ?? ""}`;
  return { ok: res.status === 0, code: res.status, out, missing: false };
}

/** The Godot binary: $GODOT, else "godot" on PATH. */
export function godotBin() {
  return process.env.GODOT || "godot";
}

export function block(message) {
  process.stderr.write(message.endsWith("\n") ? message : message + "\n");
  process.exit(2);
}

export { existsSync };
