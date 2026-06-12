#!/usr/bin/env python3
"""Scan html/locales/<code>/translation.json, collect _meta blocks, emit:
  - data/meta/languages.xml  (for XSLT build-time / html_navbar.xsl)
  - html/locales/manifest.json  (for i18n.js runtime)

Each translation.json may declare a top-level "_meta" object:
  {"nativeName": "Deutsch", "code": "DE", "complete": true}

Missing fields fall back to sensible defaults (folder name uppercased).
Only languages with complete=true end up in the switcher; incomplete ones
are still exported but marked, so a downstream consumer can decide.
"""
from __future__ import annotations

import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LOCALES_DIR = ROOT / "html" / "locales"
OUT_XML = ROOT / "data" / "meta" / "languages.xml"
OUT_JSON = ROOT / "html" / "locales" / "manifest.json"


def collect_languages() -> list[dict]:
    languages: list[dict] = []
    for entry in sorted(LOCALES_DIR.iterdir()):
        if not entry.is_dir():
            continue
        translation_file = entry / "translation.json"
        if not translation_file.exists():
            continue
        try:
            data = json.loads(translation_file.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            print(f"WARN: {translation_file} invalid JSON: {exc}", file=sys.stderr)
            continue
        meta = data.get("_meta") or {}
        code = entry.name
        languages.append({
            "code": code,
            "nativeName": meta.get("nativeName", code.capitalize()),
            "shortCode": meta.get("code", code.upper()),
            "complete": bool(meta.get("complete", False)),
        })
    return languages


def write_xml(languages: list[dict]) -> None:
    OUT_XML.parent.mkdir(parents=True, exist_ok=True)
    root = ET.Element("languages")
    for lang in languages:
        ET.SubElement(
            root,
            "language",
            code=lang["code"],
            nativeName=lang["nativeName"],
            shortCode=lang["shortCode"],
            complete=str(lang["complete"]).lower(),
        )
    ET.indent(root, space="  ")
    OUT_XML.write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        + ET.tostring(root, encoding="unicode")
        + "\n",
        encoding="utf-8",
    )


def write_json(languages: list[dict]) -> None:
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(
        json.dumps({"languages": languages}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def main() -> int:
    if not LOCALES_DIR.is_dir():
        print(f"ERROR: {LOCALES_DIR} not found", file=sys.stderr)
        return 1
    languages = collect_languages()
    if not languages:
        print(f"ERROR: no locales found in {LOCALES_DIR}", file=sys.stderr)
        return 1
    write_xml(languages)
    write_json(languages)
    codes = ", ".join(f"{l['code']}({'x' if l['complete'] else '·'})" for l in languages)
    print(f"Wrote manifest with {len(languages)} language(s): {codes}")
    print(f"  -> {OUT_XML.relative_to(ROOT)}")
    print(f"  -> {OUT_JSON.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
