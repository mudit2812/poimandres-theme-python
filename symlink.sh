#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

EXT_ID="$(
  python3 -c "
import json
from pathlib import Path

package = json.loads((Path('${ROOT}') / 'package.json').read_text())
print(f\"{package['publisher']}.{package['name']}-{package['version']}\")
"
)"

link_extension() {
  local extensions_dir="$1"
  local target="${extensions_dir}/${EXT_ID}"

  mkdir -p "${extensions_dir}"

  if [[ -L "${target}" ]]; then
    rm "${target}"
  elif [[ -e "${target}" ]]; then
    echo "Error: ${target} exists and is not a symlink. Remove it manually." >&2
    exit 1
  fi

  ln -s "${ROOT}" "${target}"
  echo "Linked ${target} -> ${ROOT}"
}

link_extension "${HOME}/.cursor/extensions"
link_extension "${HOME}/.vscode/extensions"
