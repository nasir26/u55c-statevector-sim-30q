#!/bin/bash
# Syntax checks of every Python and shell source; ruff (rules in pyproject.toml) when it is installed.
# usage: scripts/lint.sh [python]
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
PY=${1:-python3}
mapfile -t py < <(git ls-files '*.py' 2>/dev/null || find . -name '*.py' -not -path './envs/*' -not -path './build/*')
mapfile -t sh < <(git ls-files '*.sh' 'env.sh' 2>/dev/null || find . -name '*.sh' -not -path './envs/*')
"$PY" - "${py[@]}" <<'PYEOF'
import ast, sys
bad = 0
for f in sys.argv[1:]:
    try:
        ast.parse(open(f, encoding="utf-8").read(), f)
    except SyntaxError as e:
        print(f"{f}:{e.lineno}: {e.msg}"); bad += 1
print(f"python syntax: {len(sys.argv) - 1} files, {bad} errors"); sys.exit(1 if bad else 0)
PYEOF
for f in "${sh[@]}"; do bash -n "$f"; done; echo "shell syntax: ${#sh[@]} files ok"
if command -v ruff >/dev/null; then ruff check .; else echo "ruff not installed: skipped (CI runs it)"; fi
