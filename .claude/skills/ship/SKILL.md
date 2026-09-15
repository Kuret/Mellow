---
name: ship
description: Take what matters from upstream WebLibre and Zen's sync contract, merge it, verify it, and cut a signed GitHub release with written notes. Use when asked to update Mellow from upstream, check for upstream changes and release, ship a new version, or make a release.
user-invocable: true
---

# Ship

**Arguments:** $ARGUMENTS

One pass from "what moved upstream" to "a signed APK on the releases page". It is a chain of gates, and **stopping at a gate with an honest report is a successful run** — a release nobody can trust is worse than no release.

Useful arguments: `--local-only` (skip the upstream check and release the work already on `zen-model`), `--draft` (publish the release as a draft), `patch` / `minor` (force the version bump).

## What this skill does not decide

The triage policy — what to take from upstream and what to leave — lives in the **`upstream-sync`** skill, which measured it. Do not restate or re-derive it here. This skill invokes that one and then carries its result the rest of the way.

Likewise the signing and publishing rules live in `scripts/release.sh`. Do not reimplement them inline; if the script refuses something, the script is right.

## Step 1 — Upstream and Zen

Unless `--local-only`, invoke the `upstream-sync` skill and follow it through **its Step 5**, which covers: the triage report, the Zen sync-contract diff, building the branch through the identifier patch filter, verification, and moving the markers in `state.json`.

Two outcomes are both fine:

- **Nothing to take.** A quiet quarter is a real result. Go to Step 2 — there may still be local work worth releasing.
- **Commits merged.** Carry the list of what was taken and skipped into the notes; it is the most useful part of them.

That skill's four stop conditions end this run too, with no release: Zen's engine version moved, upstream changed the drift schema under our tables, a conflict needs a data-model decision, or tests fail in a way that implicates sync or tab code. Report and hand back.

## Step 2 — Is there anything to release?

```
gh release list --repo Kuret/Mellow --limit 1 --json tagName --jq '.[0].tagName'
git log --no-merges --oneline <that tag>..HEAD
```

**Ask GitHub, not `git describe`.** WebLibre's own `v0.1.0` … `v0.30.0` tags are in this history — 204 of them — so a bare `v0.1.0` names one of *theirs*, and `git describe` will happily answer with an upstream tag from 2024. Mellow's tags carry a `mellow-` prefix for exactly this reason; if you must work locally, match it: `git describe --tags --abbrev=0 --match 'mellow-v*'`.

If the range is empty, **stop**: say the tree is already released and what the last tag was. Never cut a release whose only content is a version bump.

## Step 3 — Version

`apps/mellow/pubspec.yaml` carries `<name>+<code>` — the name becomes the tag (`0.1.0` → `mellow-v0.1.0`), the code is Android's version code.

- The **code always increases by one.** Android refuses an update whose code went down, and a wasted code costs nothing.
- The **name** follows what is in the log: anything a user would notice → minor (`0.2.0`); only fixes and internals → patch (`0.1.1`). `$ARGUMENTS` overrides.

Commit the bump on its own, with the version in the subject.

## Step 4 — Write the notes

The part no script can do, and the reason this skill exists. `scripts/release.sh` falls back to a list of commit subjects, which is a changelog written for the person who already knows what changed.

Write for the one person who will read this on a phone, deciding whether to install. Sections, in this order, **omitting any that would be empty**:

```markdown
One sentence on what this release is for.

## New
- Things that can now be done, in behaviour, not implementation.

## Fixed
- What was wrong, described as the symptom that was noticed.

## From upstream
- What came from WebLibre, each with its short sha and one line of why.
- Zen's sync contract: checked at <sha>, engine version N, unchanged.

## Internal
- One line total, or leave the section out. Refactors are not news.
```

Rules that keep them worth reading:

- **Behaviour, not commits.** "Spaces remember the tab you were last on" — not "add SpaceLastTab notifier".
- One bullet per thing a person would notice, not one per commit. Five commits of one feature are one bullet.
- Name the Zen contract status every time, even when unchanged. It is the thing most likely to break silently, and the release note is the only record that it was looked at.
- **Say what was not verified.** If no device was attached, the notes say so. The release page is the only place that caveat will survive.

Write it to the scratchpad, not the repo, and pass the path on.

## Step 5 — Release

```
./scripts/release.sh --notes-file <path>
```

It refuses a dirty tree, refuses an existing tag, pushes the commit it is about to tag, runs the suite, builds the arm64 release APK, **reads the certificate back out of the APK and refuses to publish a debug-signed one**, then creates the GitHub release with the APK and its SHA-256.

If a device is attached (`mcp__android__*`, per the android skill — not raw `adb`), install the built APK and smoke-test before announcing: a space switches, a tab opens, Settings → Firefox Sync shows the account. Note the result in the report either way.

> The first release-signed build could not be installed over the debug-signed ones that came before it. If an install fails with a signature error, that is why, and the fix is uninstalling the old app — say so rather than retrying.

## Step 6 — Report

Give the release URL, then: what was taken and skipped, the Zen contract status, the verification results, and the one thing most worth watching in this release. Keep it to a few lines; the notes carry the detail.

Then update `.claude/skills/upstream-sync/state.json` markers if Step 1 did not already, and add a memory entry only if something structural changed — a new schema version, a new sync behaviour, a new stop condition worth knowing next time.

## Stop and ask, do not improvise

Beyond `upstream-sync`'s four: the signing environment is missing or `scripts/release.sh` refuses the APK it built; the tag already exists; the version code would not increase; or the suite has any failure at all — there are no pre-existing ones left to excuse. In each case leave the work committed on `zen-model`, publish nothing, and report what blocked it.
