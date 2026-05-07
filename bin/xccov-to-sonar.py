#!/usr/bin/env python3
"""Convert an Xcode .xcresult bundle to SonarCloud generic test coverage XML.

Usage: bin/xccov-to-sonar.py <path-to-xcresult> [--repo-root <path>]

Writes XML to stdout. Source paths are emitted relative to --repo-root
(default: current working directory) so SonarCloud can match them against
the files it scans.
"""
import argparse
import json
import os
import subprocess
import sys
from xml.sax.saxutils import escape


def xccov_report(xcresult: str) -> dict:
    out = subprocess.check_output(
        ["xcrun", "xccov", "view", "--report", "--json", xcresult],
        text=True,
    )
    return json.loads(out)


def xccov_file_lines(xcresult: str, path: str) -> str:
    return subprocess.check_output(
        ["xcrun", "xccov", "view", "--archive", "--file", path, xcresult],
        text=True,
    )


def parse_line_hits(raw: str):
    """Yield (line_number, covered:bool) for executable lines only."""
    for line in raw.splitlines():
        line = line.strip()
        if not line:
            continue
        head, _, rest = line.partition(":")
        try:
            lineno = int(head.strip())
        except ValueError:
            continue
        token = rest.strip().split()[0] if rest.strip() else ""
        if token in ("", "*"):
            # Non-executable (whitespace, comment, etc.) — skip.
            continue
        try:
            hits = int(token)
        except ValueError:
            continue
        yield lineno, hits > 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("xcresult")
    ap.add_argument("--repo-root", default=os.getcwd())
    args = ap.parse_args()

    repo_root = os.path.abspath(args.repo_root)
    report = xccov_report(args.xcresult)

    print('<?xml version="1.0" encoding="UTF-8"?>')
    print('<coverage version="1">')

    seen = set()
    for target in report.get("targets", []):
        for f in target.get("files", []):
            path = f.get("path") or ""
            if not path or path in seen:
                continue
            seen.add(path)
            if not path.startswith(repo_root):
                continue
            rel = os.path.relpath(path, repo_root)
            try:
                raw = xccov_file_lines(args.xcresult, path)
            except subprocess.CalledProcessError:
                continue
            print(f'  <file path="{escape(rel)}">')
            for lineno, covered in parse_line_hits(raw):
                print(
                    f'    <lineToCover lineNumber="{lineno}" '
                    f'covered="{"true" if covered else "false"}"/>'
                )
            print('  </file>')

    print('</coverage>')


if __name__ == "__main__":
    sys.exit(main())
