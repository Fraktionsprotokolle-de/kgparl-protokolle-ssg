#!/usr/bin/env python3
"""Prepare a build-only directory containing only well-formed XML files."""

from __future__ import annotations

import argparse
import shutil
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Validate XML files, copy well-formed files to a build directory, "
            "and write invalid files to a report."
        )
    )
    parser.add_argument("--source", required=True, type=Path, help="Source XML directory.")
    parser.add_argument("--dest", required=True, type=Path, help="Destination for valid XML files.")
    parser.add_argument("--report", required=True, type=Path, help="Report file to write.")
    parser.add_argument("--label", default="xml", help="Human-readable input label for the report.")
    parser.add_argument("--recursive", action="store_true", help="Scan source directory recursively.")
    return parser.parse_args()


def iter_xml_files(source: Path, recursive: bool) -> list[Path]:
    iterator = source.rglob("*.xml") if recursive else source.glob("*.xml")
    return sorted(path for path in iterator if path.is_file())


def validate_xml(path: Path) -> tuple[bool, str | None]:
    try:
        ET.parse(path)
    except ET.ParseError as error:
        line, column = error.position
        return False, f"line {line}, column {column}: {error}"
    except OSError as error:
        return False, str(error)
    return True, None


def copy_valid_file(source_file: Path, source_root: Path, dest_root: Path) -> None:
    relative = source_file.relative_to(source_root)
    dest_file = dest_root / relative
    dest_file.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source_file, dest_file)


def main() -> int:
    args = parse_args()
    source = args.source.resolve()
    dest = args.dest.resolve()
    report = args.report.resolve()

    if not source.is_dir():
        print(f"Source directory does not exist: {source}", file=sys.stderr)
        return 2
    if source == dest:
        print("Destination must not be the same directory as source.", file=sys.stderr)
        return 2

    report.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists():
        shutil.rmtree(dest)
    dest.mkdir(parents=True, exist_ok=True)

    xml_files = iter_xml_files(source, args.recursive)
    valid_count = 0
    invalid: list[tuple[Path, str]] = []

    for xml_file in xml_files:
        is_valid, error = validate_xml(xml_file)
        if is_valid:
            copy_valid_file(xml_file, source, dest)
            valid_count += 1
        else:
            invalid.append((xml_file, error or "unknown XML parse error"))

    with report.open("w", encoding="utf-8") as handle:
        handle.write(f"XML preflight report for {args.label}\n")
        handle.write(f"Source: {source}\n")
        handle.write(f"Valid build input: {dest}\n")
        handle.write(f"Checked: {len(xml_files)} file(s)\n")
        handle.write(f"Valid: {valid_count}\n")
        handle.write(f"Invalid: {len(invalid)}\n")
        if invalid:
            handle.write("\nInvalid XML files skipped for this build:\n")
            for xml_file, error in invalid:
                handle.write(f"Fatal Error! {xml_file}: {error}\n")
        handle.write("\n")

    print(
        f"XML preflight: {valid_count} valid, {len(invalid)} invalid "
        f"({report})"
    )
    return 1 if invalid else 0


if __name__ == "__main__":
    raise SystemExit(main())
