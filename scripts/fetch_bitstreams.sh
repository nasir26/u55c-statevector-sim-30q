#!/bin/bash
# Downloads the bitstreams used for the measurements from the GitHub release "bitstreams-v1" of this repository,
# places each at the path listed in bitstreams.sha256 (the path the scripts expect) and checks its SHA-256.
# The release asset name is the path with "/" replaced by "__".
# Uses the GitHub CLI when it is installed and logged in (works for private repositories), otherwise curl, wget
# or Python on the public download URL.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
REPO=${REPO:-nasir26/u55c-statevector-sim-30q}; TAG=${TAG:-bitstreams-v1}
URL=https://github.com/$REPO/releases/download/$TAG
get() {  # get <asset> <destination>
  if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
    gh release download "$TAG" -R "$REPO" -p "$1" -O "$2" --clobber
  elif command -v curl >/dev/null; then curl -fL --retry 3 -o "$2" "$URL/$1"
  elif command -v wget >/dev/null; then wget -q -O "$2" "$URL/$1"
  else python3 -c 'import sys, urllib.request; urllib.request.urlretrieve(sys.argv[1], sys.argv[2])' "$URL/$1" "$2"; fi
}
while read -r sha path; do
  [ -z "$sha" ] && continue
  if [ -f "$path" ] && echo "$sha  $path" | sha256sum -c --quiet - 2>/dev/null; then echo "ok (present) $path"; continue; fi
  mkdir -p "$(dirname "$path")"
  get "${path//\//__}" "$path"
  echo "$sha  $path" | sha256sum -c -
done < bitstreams.sha256
