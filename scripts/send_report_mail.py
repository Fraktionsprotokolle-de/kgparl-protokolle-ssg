#!/usr/bin/env python3
"""Send a build report via mail/mailx with robust recipient splitting."""

from __future__ import annotations

import argparse
import re
import shlex
import subprocess
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Send a text report via mail.")
    parser.add_argument("--report", required=True, type=Path, help="Report file to send as body.")
    parser.add_argument("--subject", required=True, help="Mail subject.")
    parser.add_argument(
        "--to",
        required=True,
        help="Recipient list separated by commas and/or whitespace.",
    )
    parser.add_argument(
        "--command",
        default="mail",
        help="Mail command, e.g. 'mail' or 'mailx'.",
    )
    return parser.parse_args()


def split_recipients(value: str) -> list[str]:
    return [item for item in re.split(r"[\s,]+", value.strip()) if item]


def main() -> int:
    args = parse_args()
    report = args.report.resolve()
    recipients = split_recipients(args.to)
    command = shlex.split(args.command)

    if not report.is_file():
        print(f"Report file does not exist: {report}", file=sys.stderr)
        return 2
    if not recipients:
        print("No mail recipients configured.", file=sys.stderr)
        return 2
    if not command:
        print("No mail command configured.", file=sys.stderr)
        return 2

    print(f"Sending {report} to {', '.join(recipients)}", flush=True)
    try:
        result = subprocess.run(
            [*command, "-s", args.subject, *recipients],
            input=report.read_bytes(),
            check=False,
        )
    except OSError as error:
        print(f"Could not execute mail command {args.command!r}: {error}", file=sys.stderr)
        return 127

    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
