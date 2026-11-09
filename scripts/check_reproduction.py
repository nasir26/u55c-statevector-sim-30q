"""Compare regenerated outputs with the committed ones.

Tables, macros and processed CSVs: every tracked file under paper/generated/ and results/processed/ is compared
with its committed version (git HEAD). Differences listed in tests/expected/known_differences.txt are reported but
allowed; any other difference fails.

Figures: each regenerated PDF in the figure directory is compared with the submitted figure of the same name in
paper/manuscript/ by content (all drawing streams and objects), ignoring creation dates and byte offsets, which
differ between runs.

usage: python scripts/check_reproduction.py <figure dir>
"""
import os
import re
import subprocess
import sys
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIRS = ["paper/generated", "results/processed"]
KNOWN = os.path.join(ROOT, "tests", "expected", "known_differences.txt")


def git(*args):
    return subprocess.run(["git", "-C", ROOT, *args], check=True, capture_output=True).stdout


def known_differences():
    """path -> set of line prefixes allowed to change ('*' allows the whole file)."""
    allowed = {}
    for line in open(KNOWN):
        line = line.split("#", 1)[0].strip()
        if not line:
            continue
        path, _, prefix = line.partition(" ")
        allowed.setdefault(path, set()).add(prefix.strip() or "*")
    return allowed


def changed_lines(old, new):
    a, b = old.splitlines(), new.splitlines()
    return [x for x in a if x not in b] + [x for x in b if x not in a]


def pdf_objects(path):
    data = open(path, "rb").read()
    out = []
    for m in re.finditer(rb"(\d+) 0 obj\s*(.*?)endobj", data, re.S):
        body = m.group(2)
        if b"/CreationDate" in body or b"/Producer" in body:
            continue
        s = re.search(rb"stream\r?\n(.*?)\r?\nendstream", body, re.S)
        if s:
            raw = s.group(1)
            try:
                raw = zlib.decompress(raw)
            except zlib.error:
                pass
            out.append(re.sub(rb"/Length \d+", b"", body[: s.start()]).strip() + b"|" + raw)
        else:
            out.append(body.strip())
    return out


def main():
    fig_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "build", "figures")
    allowed = known_differences()
    failures, notes = [], []

    tracked = git("ls-files", "--", *DIRS).decode().split()
    for path in tracked:
        committed = git("show", f"HEAD:{path}").decode()
        current = open(os.path.join(ROOT, path)).read()
        if committed == current:
            continue
        diff = changed_lines(committed, current)
        ok = allowed.get(path, set())
        unexplained = [x for x in diff if "*" not in ok and not any(x.startswith(p) for p in ok)]
        if unexplained:
            failures.append(f"{path}: {len(unexplained)} changed line(s), first: {unexplained[0][:100]}")
        else:
            notes.append(f"{path}: known difference ({len(diff)} line(s), see docs/KNOWN_DIFFERENCES.md)")
    print(f"tables and processed data: {len(tracked)} files compared")

    figs = sorted(f for f in os.listdir(os.path.join(ROOT, "paper", "manuscript")) if f.endswith(".pdf"))
    for name in figs:
        new = os.path.join(fig_dir, name)
        if not os.path.exists(new):
            failures.append(f"figure {name} was not regenerated")
        elif pdf_objects(new) != pdf_objects(os.path.join(ROOT, "paper", "manuscript", name)):
            failures.append(f"figure {name} differs from paper/manuscript/{name}")
    print(f"figures: {len(figs)} compared with paper/manuscript/")

    for n in notes:
        print("NOTE", n)
    for f in failures:
        print("FAIL", f)
    print("reproduction check:", "FAILED" if failures else "passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
