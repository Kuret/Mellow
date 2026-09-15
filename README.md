<p align="center">
  <img width="180" src="apps/mellow/assets/icon/icon.png" alt="Mellow">
</p>

<h1 align="center">Mellow</h1>

<p align="center"><strong>A calm, space-first Android browser that syncs with Zen Browser.</strong></p>

<p align="center">
  <a href="COPYING"><img alt="License: AGPL-3.0-or-later" src="https://img.shields.io/badge/license-AGPL--3.0--or--later-blue"></a>
  <a href="https://github.com/FaFre/WebLibre"><img alt="Fork of WebLibre" src="https://img.shields.io/badge/fork%20of-WebLibre-lightgrey"></a>
</p>

Mellow is a fork of [**WebLibre**](https://github.com/FaFre/WebLibre) rebuilt around
[**Zen Browser**](https://zen-browser.app)'s data model — spaces, nested folders, essentials, a
vertical rail — and wired into Zen's own `spaces` Firefox Sync engine, so the spaces you keep on
the desktop are the spaces you get on the phone, in both directions.

Underneath it is still WebLibre's browser: Mozilla's [Gecko](https://wiki.mozilla.org/Gecko)
engine driven through [Mozilla Android Components](https://mozac.org/), which is why pages render
and Firefox extensions behave the way they do in Firefox for Android.

> [!NOTE]
> **This is a personal build.** It exists because one person wanted Zen's spaces on their phone
> with extensions that work. There are no releases, no store listing, no roadmap and no support.
> It is not affiliated with, endorsed by or supported by WebLibre, OnDevice UG, Zen Browser or
> Mozilla. If you want a maintained privacy browser, go and use [WebLibre](https://weblibre.eu) —
> it is the better-tested software and it is where this one came from.

## What it does

- **Zen spaces, two ways.** A Sync 1.5 client for Zen's `spaces` collection (engine version 3):
  spaces, their order, icons, theme and pinned-tab containers round-trip with the desktop. Local
  state stays local, and the uploader is hardened against the tombstone bug that has eaten spaces
  upstream.
- **The Zen shape.** Spaces with nested folders and essentials, a wide vertical rail on tablets
  and unfolded screens, a compact bar on phones, and an optional slide-out rail that a back-edge
  swipe pulls in from either side.
- **Extensions.** Firefox-compatible WebExtensions, kept first-class. Everything else in this fork
  was judged against whether it got in the way of that or of sync.
- **Firefox Sync for the rest.** History, bookmarks and tabs over the same account.
- **Less of everything else.** Roughly 128k lines of upstream features were removed rather than
  carried — see [what changed](docs/CHANGES-FROM-WEBLIBRE.md).

## Status

Built and run daily on exactly one device (a Samsung foldable, Android 17). It is not tested
anywhere else, on any other screen, or by anyone else. Treat everything here as "works for me".

Mellow has its own application id (`app.mellow.browser`), so it installs beside WebLibre rather
than over it and never touches WebLibre's update channel.

## Building

```bash
# Flutter 3.47.3, JDK 17, Android SDK
dart pub global activate melos
melos bootstrap
melos run update-assets      # downloads the external data files
melos run build-components   # builds the readability JS bundle
melos run build              # build_runner across the workspace

cd apps/mellow
flutter build apk --release --flavor alpha --split-per-abi \
  --target-platform android-arm64 --no-tree-shake-icons
```

`build.gradle` falls back to debug signing when `KEY_PATH` is unset.

## Credits

Mellow is other people's work with a different shape on top. In order of how much is owed:

- **[WebLibre](https://github.com/FaFre/WebLibre)** by **Fabian Freund** / OnDevice UG — the
  browser. Engine integration, extensions, containers, the whole Flutter↔Android Components
  bridge, and the four plugin packages this repo still ships. AGPL-3.0-or-later; Mellow is a
  derivative work and stays under the same licence.
- **[Zen Browser](https://github.com/zen-browser/desktop)** — the spaces model and the sync
  record format Mellow speaks. No Zen code is copied here; the client was written against the
  behaviour of Zen's own sync engine so the two agree on the wire.
- **[Mozilla](https://mozilla.org)** — GeckoView, Android Components and Firefox Sync, under
  MPL-2.0.

Full attribution, including the bundled third-party assets, is in [NOTICE](NOTICE).

## License

Mellow is free software under the
[GNU Affero General Public License v3.0 or later](COPYING), inherited from WebLibre. Every
source file keeps its original copyright header. Changes made in this fork are documented in
[docs/CHANGES-FROM-WEBLIBRE.md](docs/CHANGES-FROM-WEBLIBRE.md), as AGPL §5 asks.

The name **Mellow** and its icon are this fork's own. The names WebLibre, Zen Browser, Firefox
and Mozilla belong to their owners and are used here only to say, factually, what this software
is built on and talks to.
