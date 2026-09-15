# What Mellow changed in WebLibre

This is the "prominent notice" the AGPL (§5a) asks a modified version to carry, and a map for
anyone — including future me — trying to work out why this tree no longer looks like its upstream.

**Forked from** WebLibre `v0.30.0-alpha-11` (commit `045de46b`, 2026-09-10).
**Modified from** 2026-09-11 onwards, on branch `zen-model`.
**Scale** as of 2026-09-15: 451 commits, 1,402 files touched, +110,712 / −873,311 lines. Most of
that deletion is data, not code: ~654k lines were the Tor package's bundled GeoIP tables. The code
itself lost ~168k lines in the app and ~37k in the plugin layer.

Two goals decided every one of those commits: **parity with Zen Browser's spaces sync**, and
**keeping WebExtension support working**. Anything that served neither was a candidate for
deletion.

---

## 1. Added: a Zen Browser sync client

The reason this fork exists.

- A **Sync 1.5 client for Zen's `spaces` collection** (engine version 3), speaking the record
  format Zen's own sync engine writes: spaces with their order, icon, theme and container binding,
  plus the pinned-tab essentials. It round-trips — desktop edits land on the phone and phone edits
  land on the desktop.
- **Local-only state never leaves the device.** The projection layer separates what Zen owns from
  what this client keeps for itself (last-used tab per space, rail side, accent), because uploading
  a local field is how you corrupt somebody else's browser.
- **Tombstone canaries.** Upstream Zen has a bug where a sync round can delete spaces. The
  uploader refuses to write a payload that would tombstone records it did not mean to, and a test
  suite (`spaces_sync_canary_test.dart`) pins the shapes that must never be sent.
- Firefox Sync's own engines — history, bookmarks, tabs — still run, over the same account.

## 2. Reshaped: the data model and the chrome

WebLibre organises browsing into containers and isolated tabs. Mellow organises it the way Zen
does, and rebuilt the browser chrome around it.

- **Spaces, nested folders, essentials.** Tabs live in a space; folders nest arbitrarily deep;
  pinned tabs are per-space essentials. Every space remembers the tab it was last on, so switching
  back lands where you left rather than on a new-tab page.
- **A wide vertical rail** on unfolded and tablet-sized screens (Zen-shaped: flat glyphs, the
  active space taking the accent), a **compact bar** on phones, and an optional **slide-out rail**
  that an Android predictive-back swipe from either edge drags in — with the other edge still
  going back, and the panel staying open while you hunt through tabs.
- **One toolbar.** The contextual button strip was removed as a place; the configured button set is
  drawn by the toolbar row itself, above the address bar, and can be hidden entirely (the way back
  in is a long-press on the space switcher).
- **Handedness** throughout: which side the space switcher sits on, which edge the rail docks to,
  and a swipe that moves it.
- **A spotlight-shaped URL popup**: field first, suggestions and history as you type, no
  recent-searches dead space.

## 3. Reshaped: settings, theme, search

- **Settings were reorganised** from upstream's list into eight categories behind one search box
  (Appearance & Layout, Tabs & Spaces, Links & Sites, Search, Privacy & Security, Extensions,
  Firefox Sync, Advanced), two-pane on wide screens. Dozens of options were deleted in favour of
  fixed defaults; every retired section title survives as a search keyword.
- **The fork owns its own settings model** (`ZenSettings`, a separate partition of the settings
  table) rather than extending upstream's, so the two can diverge without fighting.
- **A new theme.** Neutral black/white/grey surfaces built by hand instead of Material 3's seeded
  tint, hairline borders instead of grey section fills, and a single user-chosen accent driving
  every highlight, toggle and selection. Android dynamic colour now only supplies that accent.
- **Search was rebuilt**: upstream's "bangs" database and hosted search were replaced by a provider
  model with custom engines. Defaults are Brave for search and suggestions.
- **Profile defaults**: a service seeds uBlock's optimised lists and 177 privacy preferences once
  per profile. The aggressive ones (RFP, WebGL and JIT disabling, local-network blocking) are left
  opt-in because they break sites.

## 4. Removed

Twelve phases of deletion, tracked in `plans/REMOVALS.md`. By area:

| Area | Gone |
| --- | --- |
| Hosted service tier | Accounts, search credits, web search, PrivacyPass — which took the whole Rust build step with it |
| Network | Tor integration and the multi-protocol proxy client (with their GeoIP data) |
| Tabs | Isolated tabs, child/parent tab trees, tab-direction settings |
| Home | Quotes, popular sites, history highlights, wallpapers, the onboarding wizard |
| Content | Feeds, small web, bangs, reader *view*, top sites, open-link tools |
| AI | The ML engine extension, on-device models, translation |
| Other | Web push (UnifiedPush was its only transport), the quick-switcher buttons, the home search bar option |

Readability *extraction* stayed — it feeds local full-text search. Containers, bookmarks, history,
find-in-page, context menus, app links and the intent gatekeeper all stayed.

## 5. Added: developer affordances

- A **remote debugging** toggle (`adb forward tcp:6000 localabstract:<app-id>/firefox-debugger-socket`
  → `about:debugging`).
- **Eruda** as an on-device element inspector, in the page menu.

## 6. Schema migrations

Forks that change the data model owe migrations, not fresh installs:

- tabs `v20 → v21` — drop `parent_id` with the tab tree.
- user `v11 → v12` — search history.
- user `v12 → v13` — the fork's own settings partition.
- user `v13 → v14` — drop onboarding state.
- user `v14 → v15` — drop the quick-switcher button table.

## 7. How this fork tracks upstream

Measured, not guessed: 78% of upstream's last 200 commits touch a file this fork has modified, and
replaying our patch over a three-month upstream jump produced 114 conflicts against 79 clean files.
So Mellow **tracks upstream selectively**: it takes the plugin layer (GeckoView / Android
Components), dependency and build upkeep, and fixes to files it does not touch — roughly 42% of
upstream's work, and the part that would otherwise have to be maintained here. It leaves upstream's
tab, browser and UI feature work alone, because this fork replaced those semantics and a textually
clean merge can still be wrong.

The internal identifiers were deliberately **not** renamed for the same reason: the Dart package is
still `weblibre`, the Kotlin packages are still `eu.weblibre.*`, and the application id is still
`eu.weblibre.gecko`. Renaming them would buy nothing technical and would cost the ability to take
upstream's engine-layer fixes. Only what a user sees says Mellow.
