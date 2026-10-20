#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Run this script with VS Code fully quit so it does not overwrite the extension index."

EXT_ID="$(python3 - "${ROOT}/package.json" <<'PY'
import json
import sys

with open(sys.argv[1]) as stream:
    package = json.load(stream)
print(f"{package['publisher']}.{package['name']}-{package['version']}")
PY
)"

extensions_dir="${HOME}/.vscode/extensions"
target="${extensions_dir}/${EXT_ID}"
if [[ -e "${target}" && ! -L "${target}" ]]; then
  echo "Error: ${target} exists and is not a symlink. Remove it manually." >&2
  exit 1
fi

mkdir -p "${extensions_dir}"

# Python only handles JSON, including atomic replacement of the index files.
python3 - "${ROOT}" "${extensions_dir}" <<'PY'
import json
import os
import sys
import tempfile
from pathlib import Path

root = Path(sys.argv[1])
package = json.loads((root / "package.json").read_text())
extension_id = f"{package['publisher']}.{package['name']}"
version = package["version"]
directory_name = f"{extension_id}-{version}"


def read_json(path, expected_type):
    if not path.exists():
        return expected_type()
    value = json.loads(path.read_text())
    if not isinstance(value, expected_type):
        raise ValueError(f"Unexpected JSON structure in {path}")
    return value


def write_json(path, value):
    # Replace atomically so an interrupted write cannot truncate the index.
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as stream:
        temporary = Path(stream.name)
        try:
            json.dump(value, stream, indent=2)
            stream.write("\n")
            stream.close()
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)


extensions_dir = Path(sys.argv[2])
target = extensions_dir / directory_name
index_path = extensions_dir / "extensions.json"
obsolete_path = extensions_dir / ".obsolete"
entries = read_json(index_path, list)
obsolete = read_json(obsolete_path, dict)
matching = [
    entry for entry in entries
    if entry["identifier"]["id"].lower() == extension_id.lower()
]
# Keep existing metadata while updating the version and symlink location.
entry = dict(matching[0]) if matching else {"identifier": {"id": extension_id}}
entry.update({
    "version": version,
    "location": {"$mid": 1, "path": str(target), "scheme": "file"},
    "relativeLocation": directory_name,
})
entries = [item for item in entries if item not in matching]
entries.append(entry)
obsolete.pop(directory_name, None)

write_json(index_path, entries)
if obsolete_path.exists():
    write_json(obsolete_path, obsolete)
PY

if [[ -L "${target}" ]]; then
  rm "${target}"
fi
ln -s "${ROOT}" "${target}"
echo "Linked and registered ${target} -> ${ROOT}"

echo "Done. Reopen your editor and select the theme."
