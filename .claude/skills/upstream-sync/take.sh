#!/bin/bash
# Take one upstream WebLibre commit into this fork as a translated cherry-pick.
#
#   take.sh <sha> [pathspec...]            take the commit (slice only)
#   take.sh --finish <sha>                 after resolving a conflict and
#                                          `git cherry-pick --continue`
#
# Why not `format-patch | identifiers.py | git am -3`: the identifier filter
# changes blob content, so the patch's `index` lines name blobs this repo does
# not have and `git am -3` cannot fall back to a real merge. This script instead
# builds identifier-translated copies of <sha>^ and <sha> as two real commits
# T0 <- T1 (slice only, paths translated too) and cherry-picks T1, which gives
# git a correct merge base. Authorship and message are preserved; the upstream
# sha is appended as a trailer.
#
# The slice defaults to the plugin layer plus the app's android/ tree, which is
# the policy's "take" territory. Pass extra pathspecs to widen it for one
# commit (e.g. `apps/weblibre/lib/features/geckoview` for an app follow-up).
# Generated files are always excluded: regenerate them afterwards. Files the
# commit touches that do not exist in our tree (deleted features) are skipped
# and listed.
set -u

ROOT=$(git rev-parse --show-toplevel) || exit 1
SKILL_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$ROOT" || exit 1

trailer() {
  local full
  full=$(git rev-parse "$1")
  git commit --amend --allow-empty -q -m "$(git log -1 --format=%B)

(upstream FaFre/WebLibre $full)" \
    && git log -1 --format='%h %an %ad: %s' --date=short \
    && git show --stat --format= HEAD | tail -1
}

if [ "${1:-}" = "--finish" ]; then
  trailer "$2"
  exit $?
fi

sha=$(git rev-parse "$1") || exit 1
shift

INCL=(
  packages/flutter_mozilla_components
  packages/locale_resolver
  packages/simple_intent_receiver
  packages/speech_to_text_dialog
  apps/weblibre/android
  "$@"
)
EXCL=(
  ':!packages/flutter_tor' ':!packages/flutter_singbox_proxy' ':!*singbox*'
  ':!*.g.dart' ':!*.g.kt' ':!*.freezed.dart' ':!*.drift.dart'
)

tr_path() { printf '%s' "$1" | python3 -I "$SKILL_DIR/identifiers.py"; }
# Blob filter: identifiers.rewrite over the content, binary passed through.
TR_BLOB='
import sys
sys.path.insert(0, sys.argv[1])
from identifiers import rewrite
data = sys.stdin.buffer.read()
try:
    text = data.decode("utf-8")
except UnicodeDecodeError:
    sys.stdout.buffer.write(data)
else:
    sys.stdout.buffer.write(rewrite(text).encode("utf-8"))
'
tr_blob() { python3 -I -c "$TR_BLOB" "$SKILL_DIR"; }

BASE=(); NEW=()
while read -r status p1 p2; do
  case "$status" in
    A*) NEW+=("$p1");;
    D*) if [ -e "$(tr_path "$p1")" ]; then BASE+=("$p1"); else echo "SKIP-MISSING(D) $p1"; fi;;
    M*|T*) if [ -e "$(tr_path "$p1")" ]; then BASE+=("$p1"); NEW+=("$p1"); else echo "SKIP-MISSING $p1"; fi;;
    R*|C*) if [ -e "$(tr_path "$p1")" ]; then BASE+=("$p1"); NEW+=("$p2"); else echo "SKIP-MISSING(R) $p1 -> $p2"; fi;;
    *) echo "UNKNOWN STATUS $status $p1"; exit 3;;
  esac
done < <(git show --name-status --format= "$sha" -- "${INCL[@]}" "${EXCL[@]}")

if [ ${#NEW[@]} -eq 0 ] && [ ${#BASE[@]} -eq 0 ]; then
  echo "EMPTY SLICE: $sha touches nothing in the slice that exists here"
  exit 2
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

mktree() { # rev files...
  local rev=$1; shift
  export GIT_INDEX_FILE="$TMP/idx"
  rm -f "$GIT_INDEX_FILE"
  local f mode blob
  for f in "$@"; do
    mode=$(git ls-tree "$rev" -- "$f" | awk '{print $1}')
    blob=$(git cat-file blob "$rev:$f" | tr_blob | git hash-object -w --stdin)
    git update-index --add --cacheinfo "$mode,$blob,$(tr_path "$f")"
  done
  git write-tree
  unset GIT_INDEX_FILE
}

t0=$(mktree "$sha^" "${BASE[@]}")
t1=$(mktree "$sha" "${NEW[@]}")
T0=$(git commit-tree "$t0" -m "translated base of $sha")
git log -1 --format=%B "$sha" > "$TMP/msg"
T1=$(GIT_AUTHOR_NAME="$(git log -1 --format=%an "$sha")" \
     GIT_AUTHOR_EMAIL="$(git log -1 --format=%ae "$sha")" \
     GIT_AUTHOR_DATE="$(git log -1 --format=%aD "$sha")" \
     git commit-tree "$t1" -p "$T0" -F "$TMP/msg")

echo "translated $sha -> $T1 (base $T0)"
echo "--- slice:"
git diff --name-status "$T0" "$T1"

if git cherry-pick "$T1"; then
  trailer "$sha"
else
  echo
  echo "CONFLICT. Resolve (ours wins in our files, upstream in theirs), then:"
  echo "  git cherry-pick --continue && $SKILL_DIR/take.sh --finish $sha"
  exit 1
fi
