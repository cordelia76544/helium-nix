#!/usr/bin/env bash
set -euo pipefail

file="flake.nix"

latest="$(
  curl -fsSL https://api.github.com/repos/imputnet/helium-linux/releases/latest |
    jq -r '.tag_name'
)"

if [[ -z "$latest" || "$latest" == "null" ]]; then
  echo "Failed to fetch latest Helium version"
  exit 1
fi

echo "Latest Helium version: $latest"

url="https://github.com/imputnet/helium-linux/releases/download/${latest}/helium-${latest}-x86_64.AppImage"

echo "Prefetching:"
echo "$url"

hash="$(
  nix store prefetch-file --json "$url" |
    jq -r '.hash'
)"

if [[ -z "$hash" || "$hash" == "null" ]]; then
  echo "Failed to prefetch hash"
  exit 1
fi

echo "New hash: $hash"

python3 - <<PY
from pathlib import Path
import re

path = Path("$file")
text = path.read_text()

old_text = text

text = re.sub(
    r'version = "[^"]+";',
    'version = "$latest";',
    text,
    count=1,
)

text = re.sub(
    r'hash = "sha256-[^"]+";',
    'hash = "$hash";',
    text,
    count=1,
)

if text == old_text:
    print("No changes made to flake.nix")
else:
    path.write_text(text)
    print("Updated flake.nix")
PY