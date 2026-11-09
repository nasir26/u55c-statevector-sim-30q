#!/bin/bash
# Builds the manuscript from paper/revised/ with the regenerated tables (paper/generated/) and figures.
# usage: scripts/build_paper.sh <figure dir> <output dir>    (needs latexmk and pdflatex, for example TeX Live 2025)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
FIG=$(realpath "${1:-build/figures}"); OUT=$(realpath -m "${2:-build/paper}")
command -v latexmk >/dev/null || { echo "latexmk not found"; exit 2; }
mkdir -p "$OUT"; rm -rf paper/revised/figures; ln -s "$FIG" paper/revised/figures
(cd paper/revised && latexmk -pdf -interaction=nonstopmode -halt-on-error -outdir="$OUT" main.tex)
rm paper/revised/figures
echo "manuscript: $OUT/main.pdf"
