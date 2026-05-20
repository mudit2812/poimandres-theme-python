#!/usr/bin/env python3
"""Generate VS Code theme JSON files from theme.py into the themes directory."""

from pathlib import Path

from theme import base, schema, storm

ROOT = Path(__file__).resolve().parent.parent.parent
THEMES_DIR = ROOT / "themes"

OUTPUTS = {
    "poimandres-python-theme.json": base,
    "poimandres-python-theme-storm.json": storm,
}


def main() -> None:
    THEMES_DIR.mkdir(parents=True, exist_ok=True)
    for filename, theme in OUTPUTS.items():
        path = THEMES_DIR / filename
        path.write_text(schema(theme) + "\n", encoding="utf-8")
        print(f"Wrote {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
