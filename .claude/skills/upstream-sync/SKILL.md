---
name: upstream-sync
description: Pull relevant changes from upstream WebLibre and check Zen's spaces-sync contract for drift, then open a PR with what belongs in this fork. Use when asked to check for upstream changes, merge an upstream release, or verify the Zen sync contract still matches our client.
user-invocable: true
---

# Upstream sync

**Arguments:** $ARGUMENTS

This repo is a hard-working fork of [WebLibre](https://github.com/FaFre/WebLibre) that replaced its tab model with Zen Browser's (spaces, nested folders, essentials, a wide vertical rail) and added a two-way sync client for Zen's own Firefox Sync `spaces` engine. Upstream is `origin`. **We never push to it and never open PRs against it.**

Two things move underneath us, and this skill checks both:

1. **WebLibre** ships ~50 commits a month. About 78% of them touch a file this fork has modified, so a blanket `git merge` is not the job — triage is.
2. **Zen** owns the sync contract our client implements. If their engine version or record shapes change, our client is wrong until we adapt it, and wrong here means someone's tabs.

## The policy this skill enforces

Measured on this fork: 188 hand-modified upstream files, 131 new ones, 312 deleted. A three-month upstream jump collides with ~87 hand-written files. So we do **not** track upstream wholesale. We take the parts that are upkeep and leave the parts we have replaced.

| Upstream change | What to do |
|---|---|
| `packages/flutter_mozilla_components/**` (GeckoView / Android Components surface) | **Take.** This is the main reason to keep tracking upstream. |
| Dependency and build upkeep (`pubspec.*`, `*.gradle`, `gradle.properties`, `.github/workflows/**`) | **Take**, but reconcile by hand — we changed `android/app/build.gradle` (debug-signing fallback when `KEY_PATH` is unset) and our `pubspec.yaml` carries our own deps. |
| Fixes to files we do not touch | **Take.** |
| Anything under `apps/weblibre/lib/features/geckoview/features/{browser,tabs}/**`, the tab repository/providers, the tab views, the menu, `general_settings.dart` | **Review, do not auto-merge.** We replaced the semantics underneath these. A textually clean merge here can still be wrong. |
| Their work on proxy / Tor / isolated tabs / strict mode | **Skip.** We deleted it (W0). Resolution is always "stays deleted". |

When in doubt, leave it out and say so in the PR. An upstream feature we skipped can be taken next time; a bad merge into the tab model costs a day.

## Step 0 — Preflight

Run everything from the repo root. The shell is fish, so wrap globs and loops in `bash -c '...'`.

- Toolchain (Java 17, Flutter, Android SDK): `bash -c 'source ../.env.sh && …'`. For APK builds also `export PATH="$HOME/.cargo/bin:$PATH"` (cargokit needs rustup for `privacypass_client`).
- Read `.claude/skills/upstream-sync/state.json`. It records the fork base and the last reviewed commit on each side. Treat it as the source of truth for "where we left off".
- Check for a remote we control: `git remote -v`. `origin` is **upstream** — it is not a PR target. A PR needs a separate remote (conventionally `fork`) pointing at a repo the user owns. If there is none, you will still do all the work locally; see Step 6.

## Step 1 — Triage WebLibre

```
python3 .claude/skills/upstream-sync/report.py
```

It fetches `origin`, computes this fork's surface from git (so it stays accurate as the fork grows), and sorts every commit since `last_reviewed` into **take** / **review** / **skip**, flagging `[plugin]` and `[upkeep]`. Use `--from`/`--to` to scope a range, `--json` to script against it.

Read the actual diff of everything in **review** — `git show <sha> -- <path>` — before deciding. The bucket is a hint, not a verdict.

## Step 2 — Check the Zen sync contract

The clone lives at the path in `state.json` (`../zen-desktop`) and tracks `origin/dev`.

```
cd ../zen-desktop && git fetch origin
git diff <zen.last_reviewed>..origin/dev -- src/zen/sync     # authoritative
git log --oneline <zen.last_reviewed>..origin/dev -- src/zen/sync   # context
```

**The tree diff is the answer; the log is only context.** If that clone is ever a shallow one (`git rev-parse --is-shallow-repository` says true), `git log <a>..<b>` silently truncates and reports far fewer commits than really landed — a skill that trusts it will report "no drift" on a contract that moved. The tree diff compares two trees and is correct either way.

Keep the clone blobless rather than shallow, which gives full history for ~38 MB. If it is missing or shallow, recreate it (seconds, and `--unshallow` on this repo instead costs ~6 minutes and 5.7 GB):

```
git clone --filter=blob:none https://github.com/zen-browser/desktop.git ../zen-desktop
```

Four files own the contract: `ZenSpacesSync.sys.mjs`, `ZenSpacesSyncModel.sys.mjs`, `ZenSpacesSyncApplier.sys.mjs`, `moz.build`. What matters, in order:

- **Engine version.** `get version()` in `ZenSpacesSync.sys.mjs` is currently `3`, mirrored in `state.json`. If it moved, **stop and report** — do not adapt the client on your own judgement. Our client already halts uploads and keeps reading when it sees a version above the one it knows; confirm that still holds, and hand the user the diff and what it implies.
- **Record shapes** in `ZenSpacesSyncModel.sys.mjs` — the six kinds (container / space / tab / folder / split / layout) and their fields. Compare against our projection and applier in `apps/weblibre/lib/features/spaces_sync/`, and against the fixtures in `apps/weblibre/test/features/spaces_sync/`. A new optional field we round-trip verbatim is harmless; a changed id format or a new required field is not.
- **Applier semantics** in `ZenSpacesSyncApplier.sys.mjs`. Our client is hardened against Zen's stale-projection race (upstream `zen-browser/desktop#15380`): stateless projection, apply mutex, digests stamped inside the apply transaction, tombstones derived only from the witnessed-deletion ledger, and a destructive-batch canary. If they fixed it upstream, say so in the PR — our defences stay either way, but the canary thresholds may be worth revisiting.
- **Prefs** the desktop expects (`services.sync.engine.spaces`, `zen.spaces-sync.normal-tabs`). If they were renamed, `dist/SETUP.md` is wrong and must be updated in the same PR.

If nothing under `src/zen/sync` changed, say exactly that — a quiet quarter is a useful result.

## Step 3 — Build the branch

Branch from `zen-model`: `git checkout -b upstream-sync/<YYYY-MM-DD>`.

Prefer **cherry-picking the commits you decided to take**, in upstream order, over merging the range. It keeps authorship, keeps each change reviewable, and stops a skipped commit from riding along:

```
git cherry-pick -x <sha>        # -x records the upstream sha in the message
```

For a large plugin-layer range, `git cherry-pick -x A^..B` is fine when every commit in it is in the take bucket. On conflict: resolve with our semantics winning in our files, upstream winning in theirs; if a conflict needs a judgement call you cannot defend in one sentence, abort that pick and list it under "not taken" instead.

Rules that save the build:

- Generated files are never hand-merged. Take ours, then regenerate: `bash -c 'source ../.env.sh && dart run build_runner build --delete-conflicting-outputs'`.
- Pigeons regenerate with **27.3.1**, never the pinned ^28: `dart pub global activate pigeon 27.3.1 && dart pub global run pigeon --input pigeons/gecko.dart` from `packages/flutter_mozilla_components`. Check `git diff --stat` afterwards — anything beyond the schema plus its two generated files means the wrong pigeon ran.
- Drift schema changes need a migration and a schema test, not just an edited `definitions.drift`. If upstream changed their schema under ours, stop and ask.

Commit style: small and focused, one concern per commit, following the trailer convention already in `git log`.

## Step 4 — Verify

Nothing gets a PR without these:

```
bash -c 'source ../.env.sh && cd apps/weblibre && dart analyze lib test'
bash -c 'source ../.env.sh && cd apps/weblibre && flutter test'
bash -c 'source ../.env.sh && export PATH="$HOME/.cargo/bin:$PATH" && cd apps/weblibre && \
  flutter build apk --release --flavor alpha --target-platform android-arm64 --split-per-abi --no-tree-shake-icons'
```

Known failures that pre-date the fork and are **not** yours: `test/drift/bangs/migration_test.dart` (×8) and `test/features/web_search/**/page_preview_test.dart` (×1). Everything else must be green.

If the APK build complains about missing assets, the gitignored build inputs are missing from this tree: `../sync-build-inputs.sh <path-to-this-worktree>`.

If a device is attached (`adb devices`), install and smoke-test it — sync settings open, a space switches, a tab opens: `adb install -r <apk>`, then `adb shell uiautomator dump` and `adb shell screencap -p -d <display-id>` to verify on screen. Say in the PR whether this happened; "not verified on device" is an acceptable answer, a silent omission is not.

## Step 5 — Update the markers

In a final commit, set `weblibre.last_reviewed` to the upstream sha you triaged up to (**even for commits you skipped** — they are reviewed, not pending) and `zen.last_reviewed` / `zen.engine_version` to what you just checked. Markers move with the review, not with the merge.

## Step 6 — Open the PR

With a pushable remote:

```
git push -u fork upstream-sync/<date>
gh pr create --repo <owner>/<repo> --base zen-model --head upstream-sync/<date> --title "…" --body "…"
```

**If there is no remote other than `origin`, do not create one and do not push.** Publishing this repo is the user's call, not yours. Stop with the branch in place, report everything, and give them the one command that would enable PRs:

```
gh repo create <name> --private --source=. --remote=fork --push
```

The PR body must contain, in this order:

1. **Taken** — each upstream commit with its sha and one line on why.
2. **Skipped** — each one with the reason (replaced by our tab model / deleted feature / deferred).
3. **Zen contract** — changed or unchanged, and what it means for our client; engine version confirmed.
4. **Verification** — the analyze/test/build results, the known-failure caveat, and whether it ran on a device.
5. **Risk** — what a reviewer should look at hardest, especially anything that touched `spaces_sync`, the drift schema, or the tab repository.

## Stop and ask, do not improvise

Hand it back to the user when:

- Zen's engine version moved above the one in `state.json`.
- Upstream changed the drift schema under our tab tables, or renamed/moved something our sync client depends on.
- A cherry-pick conflict needs a decision about our data model rather than a mechanical resolution.
- Tests fail in a way that implicates our sync or tab code, rather than an obvious mechanical break.

In all four cases: leave the branch, write the report, explain the choice you could not make. Half a triage delivered honestly beats a merged PR nobody trusts.
