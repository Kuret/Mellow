#!/usr/bin/env bash
#
# Build a signed Mellow APK and publish it to GitHub Releases.
#
# Usage: scripts/release.sh [--skip-tests] [--draft] [--notes-file PATH]
#
# The version comes from apps/mellow/pubspec.yaml — bump it there first. The
# part before "+" is the release name (0.1.0 -> tag mellow-v0.1.0); the part
# after is the Android version code, which must only ever go up.
#
# Tags carry the "mellow-" prefix on purpose: WebLibre's own v0.1.0 … v0.30.0
# tags are in this history, so a bare "v0.1.0" would name one of theirs.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$(dirname "$ROOT")"
DIST="${MELLOW_DIST:-$WORKSPACE/dist}"
REPO="${MELLOW_REPO:-Kuret/Mellow}"
REMOTE="${MELLOW_REMOTE:-mellow}"

SKIP_TESTS=0
DRAFT=()
NOTES_IN=""
while [ $# -gt 0 ]; do
  case "$1" in
    --skip-tests) SKIP_TESTS=1 ;;
    --draft) DRAFT=(--draft) ;;
    --notes-file) NOTES_IN="${2:-}"; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done
[ -z "$NOTES_IN" ] || [ -f "$NOTES_IN" ] || { echo "no such notes file: $NOTES_IN" >&2; exit 2; }

# Toolchain and signing environment live outside the repo.
# shellcheck source=/dev/null
[ -f "$WORKSPACE/.env.sh" ] && source "$WORKSPACE/.env.sh"

say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[31mrefusing: %s\033[0m\n' "$*" >&2; exit 1; }

# ── 1. signing ───────────────────────────────────────────────────────────────
# build.gradle falls back to the debug keystore when KEY_PATH is unset, and a
# debug-signed APK can never update a real install. Publishing one would be a
# mistake nobody notices until the next release refuses to install.
[ -n "${KEY_PATH:-}" ] || die "KEY_PATH is not set — see .env.sh"
[ -f "$KEY_PATH" ] || die "KEY_PATH points at nothing: $KEY_PATH"
[ -n "${KEY_ALIAS:-}" ] && [ -n "${KEY_PASSWORD:-}" ] || die "KEY_ALIAS/KEY_PASSWORD are not set"

# ── 2. version ───────────────────────────────────────────────────────────────
VERSION="$(awk '/^version:/ {print $2; exit}' "$ROOT/apps/mellow/pubspec.yaml")"
NAME="${VERSION%%+*}"
CODE="${VERSION##*+}"
TAG="mellow-v$NAME"
say "Mellow $NAME (version code $CODE), tag $TAG"

if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  die "$TAG already exists — bump the version in apps/mellow/pubspec.yaml"
fi

# ── 3. the tree must be clean and published ──────────────────────────────────
# A release points at a commit. If that commit is not on the remote, the tag
# names something nobody else can fetch.
[ -z "$(git -C "$ROOT" status --porcelain)" ] || die "working tree is dirty"
git -C "$ROOT" push "$REMOTE" HEAD:main

# ── 4. tests ─────────────────────────────────────────────────────────────────
if [ "$SKIP_TESTS" -eq 0 ]; then
  say "Running the suite"
  (cd "$ROOT/apps/mellow" && flutter test)
fi

# ── 5. build ─────────────────────────────────────────────────────────────────
say "Building"
cd "$ROOT/apps/mellow"
flutter build apk --release --flavor alpha --split-per-abi \
  --target-platform android-arm64 --no-tree-shake-icons
APK="build/app/outputs/flutter-apk/app-arm64-v8a-alpha-release.apk"
[ -f "$APK" ] || die "no APK at $APK"

# ── 6. prove it is signed with the release key ───────────────────────────────
APKSIGNER="$(find "${ANDROID_HOME:-$ANDROID_SDK_ROOT}/build-tools" -name apksigner 2>/dev/null | sort -V | tail -1)"
[ -n "$APKSIGNER" ] || die "no apksigner in the Android SDK"
CERTS="$("$APKSIGNER" verify --print-certs "$APK")"
case "$CERTS" in
  *"CN=Android Debug"*) die "this APK is debug-signed — the KEY_* environment did not reach Gradle" ;;
esac
say "Signed by"
printf '%s\n' "$CERTS" | grep -E 'Signer #1 certificate (DN|SHA-256)'

# ── 7. publish ───────────────────────────────────────────────────────────────
mkdir -p "$DIST"
OUT="$DIST/mellow-$NAME-arm64.apk"
cp "$APK" "$OUT"
SHA="$(shasum -a 256 "$OUT" | awk '{print $1}')"

# Notes: a written summary when one is supplied (the `ship` skill writes one),
# otherwise the commit subjects, which is better than nothing and worse than
# prose. The header is added either way — it is the same for every release.
PREV="$(gh release list --repo "$REPO" --limit 1 --json tagName --jq '.[0].tagName // empty' 2>/dev/null || true)"
NOTES="$(mktemp)"
{
  echo "Personal build, arm64 only, Android 8.0+. Not affiliated with WebLibre, Zen Browser or Mozilla."
  echo
  echo "\`sha256  $SHA\`"
  echo
  if [ -n "$NOTES_IN" ]; then
    cat "$NOTES_IN"
  else
    echo "## Changes"
    echo
    if [ -n "$PREV" ]; then
      git -C "$ROOT" log --no-merges --format='- %s' "$PREV..HEAD"
    else
      echo "- First release of the fork under its own name."
    fi
  fi
} > "$NOTES"

say "Publishing $TAG to $REPO"
gh release create "$TAG" "$OUT" --repo "$REPO" \
  --title "Mellow $NAME" --notes-file "$NOTES" "${DRAFT[@]}"
rm -f "$NOTES"

# gh creates the tag on the remote; without this the local clone never sees it,
# and the next run computes "changes since" against an upstream tag instead.
git -C "$ROOT" fetch --quiet "$REMOTE" --tags

say "Done — $OUT"
