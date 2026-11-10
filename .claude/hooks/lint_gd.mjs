// PostToolUse: after any .gd edit, auto-format it and lint it. Lint problems go back to Claude.
import { readInput, relPath, run, block } from "./_common.mjs";

const input = readInput();
const rel = relPath((input.tool_input || {}).file_path || "");
if (!rel.endsWith(".gd") || rel.startsWith("addons/gut/")) process.exit(0);

const fmt = run("gdformat", ["--line-length", "120", rel]);
if (fmt.missing) {
  process.stderr.write('gdtoolkit not installed; skipping lint (pip install "gdtoolkit==4.*").\n');
  process.exit(0);
}
if (!fmt.ok) block(`gdformat could not parse ${rel} (syntax error?):\n${fmt.out.trim()}`);

const lint = run("gdlint", [rel]);
if (!lint.ok) block(`gdlint found problems in ${rel}. Fix them:\n${lint.out.trim()}`);
process.exit(0);
