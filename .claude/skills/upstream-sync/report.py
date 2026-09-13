#!/usr/bin/env python3
"""Triage upstream WebLibre commits against this fork's own surface.

Every commit in the range is sorted into one of three buckets by the files it
touches, so a review is a triage list rather than a merge gamble:

  take    — touches nothing this fork has edited. Merges on its own.
  review  — touches a file this fork modified. A clean auto-merge here can
            still be semantically wrong, because the tab model underneath it
            changed. A human (or an agent that reads the diff) decides.
  skip    — touches only files this fork deleted (the proxy/Tor strip).
            Resolution is always "stay deleted".

The fork's surface is computed from git, not hardcoded, so it stays true as the
fork grows.

Usage:
  report.py                     # state.json's last_reviewed .. origin/main
  report.py --from SHA --to REF
  report.py --no-fetch          # offline, use the refs already fetched
  report.py --json              # machine-readable, for scripting
"""

import argparse
import collections
import json
import pathlib
import subprocess
import sys

SKILL_DIR = pathlib.Path(__file__).resolve().parent
STATE_PATH = SKILL_DIR / "state.json"

# Files that upstream owns and this fork only follows. Changes here are the
# reason to keep tracking upstream at all: the GeckoView / Android Components
# surface and the build upkeep that comes with it.
PLUGIN_PREFIXES = ("packages/flutter_mozilla_components/",)
UPKEEP_NAMES = (
    "pubspec.yaml",
    "pubspec.lock",
    "build.gradle",
    "build.gradle.kts",
    "gradle.properties",
    "gradle-wrapper.properties",
    "settings.gradle",
)
UPKEEP_PREFIXES = (".github/workflows/",)


def git(*args, repo=None):
    result = subprocess.run(
        ["git", *args],
        cwd=repo,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        sys.exit(f"git {' '.join(args)} failed:\n{result.stderr.strip()}")
    return result.stdout


def load_state():
    if not STATE_PATH.exists():
        sys.exit(f"missing {STATE_PATH}")
    return json.loads(STATE_PATH.read_text())


def fork_surface(fork_base):
    """The files this fork has modified and deleted since it branched."""
    modified, deleted = set(), set()
    for line in git("diff", "--name-status", f"{fork_base}..HEAD").splitlines():
        if not line.strip():
            continue
        parts = line.split("\t")
        status, path = parts[0], parts[-1]
        if status.startswith("M") or status.startswith("R"):
            modified.add(path)
        elif status.startswith("D"):
            deleted.add(path)
    return modified, deleted


def is_upkeep(path):
    return path.split("/")[-1] in UPKEEP_NAMES or path.startswith(UPKEEP_PREFIXES)


def is_plugin(path):
    return path.startswith(PLUGIN_PREFIXES)


def classify(files, modified, deleted):
    if any(f in modified for f in files):
        return "review"
    if files and all(f in deleted for f in files):
        return "skip"
    return "take"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--from", dest="frm")
    parser.add_argument("--to", dest="to")
    parser.add_argument("--no-fetch", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    state = load_state()
    remote = state["weblibre"]["remote"]
    branch = state["weblibre"]["branch"]
    frm = args.frm or state["weblibre"]["last_reviewed"]
    to = args.to or f"{remote}/{branch}"

    if not args.no_fetch:
        git("fetch", "--quiet", remote)

    modified, deleted = fork_surface(state["fork_base"])

    raw = git(
        "log",
        "--no-merges",
        "--name-only",
        "--pretty=format:@@@%H%x1f%h%x1f%ad%x1f%s",
        "--date=short",
        f"{frm}..{to}",
    )

    commits = []
    for chunk in raw.split("@@@"):
        chunk = chunk.strip("\n")
        if not chunk.strip():
            continue
        header, _, body = chunk.partition("\n")
        sha, short, date, subject = header.split("\x1f")
        files = [line.strip() for line in body.splitlines() if line.strip()]
        commits.append(
            {
                "sha": sha,
                "short": short,
                "date": date,
                "subject": subject,
                "files": files,
                "bucket": classify(files, modified, deleted),
                "plugin": any(is_plugin(f) for f in files),
                "upkeep": any(is_upkeep(f) for f in files),
                "collides": sorted(f for f in files if f in modified),
            }
        )

    if args.json:
        print(
            json.dumps(
                {"from": frm, "to": to, "commits": commits}, indent=2
            )
        )
        return

    counts = collections.Counter(c["bucket"] for c in commits)
    print(f"upstream range {frm[:9]}..{to}  —  {len(commits)} commits")
    print(
        f"  take {counts['take']:3d}   review {counts['review']:3d}   "
        f"skip {counts['skip']:3d}"
    )
    print(
        f"  fork surface: {len(modified)} modified files, "
        f"{len(deleted)} deleted files"
    )

    for bucket, title in (
        ("take", "TAKE — no overlap with this fork"),
        ("review", "REVIEW — touches files this fork modified"),
        ("skip", "SKIP — only files this fork deleted"),
    ):
        rows = [c for c in commits if c["bucket"] == bucket]
        if not rows:
            continue
        print(f"\n## {title}  ({len(rows)})")
        for c in rows:
            tags = []
            if c["plugin"]:
                tags.append("plugin")
            if c["upkeep"]:
                tags.append("upkeep")
            tag = f" [{'/'.join(tags)}]" if tags else ""
            print(f"  {c['short']} {c['date']} {c['subject']}{tag}")
            for f in c["collides"][:6]:
                print(f"      ↳ ours: {f}")
            if len(c["collides"]) > 6:
                print(f"      ↳ … {len(c['collides']) - 6} more of ours")


if __name__ == "__main__":
    main()
