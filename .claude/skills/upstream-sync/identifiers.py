#!/usr/bin/env python3
"""The fork's identifier renames, in one place.

Mellow renamed every identifier it inherited from WebLibre: the Dart package,
the app directory, the Kotlin packages, the application id, the Android
resource prefix. Upstream did not, so every patch taken from upstream speaks
the old names and would conflict on contact.

This module is the single source of truth for that mapping. It is used twice:

  * once, to rewrite the working tree when the rename happened;
  * from then on, as a patch filter, so an upstream commit arrives already
    speaking Mellow's names and applies against our tree:

        git format-patch --stdout A^..B \\
          | python3 .claude/skills/upstream-sync/identifiers.py \\
          | git am -3 --keep-non-patch

Substitutions are plain, ordered, longest-first string replacements, applied to
patch headers and content alike — which is why they must be *identifier* tokens
and never the bare word "WebLibre". Prose, licence headers ("This file is part
of WebLibre"), the weblibre.eu and github.com/FaFre/WebLibre URLs and the
settings-export format marker all contain that word and must survive untouched.
"""

from __future__ import annotations

import sys

# Ordered: every entry must run before any entry that is a prefix of it.
RENAMES: list[tuple[str, str]] = [
    # --- Dart package and the app directory -----------------------------
    ("apps/weblibre", "apps/mellow"),
    ("package:weblibre", "package:mellow"),
    ("weblibre_project", "mellow_project"),
    # pubspec / melos identity, kept narrow so it cannot hit prose
    ("name: weblibre", "name: mellow"),
    # --- Kotlin packages and the application id -------------------------
    # The app's own package is eu.weblibre.gecko, not eu.weblibre.<plugin>,
    # so it has to be rewritten before the general rule.
    ("eu.weblibre.gecko", "app.mellow.browser"),
    ("eu/weblibre/gecko", "app/mellow/browser"),
    # Deliberately no trailing separator: this one rule covers the Kotlin
    # packages (eu.weblibre.<plugin>), the platform-view ids (eu.weblibre/gecko)
    # and the bare package name alike.
    ("eu.weblibre", "app.mellow.browser"),
    ("eu/weblibre", "app/mellow/browser"),
    # --- Type and resource names ----------------------------------------
    ("WebLibreAppLinksInterceptor", "MellowAppLinksInterceptor"),
    ("WebLibreAppLinks", "MellowAppLinks"),
    ("WebLibreFxAEntryPoint", "MellowFxAEntryPoint"),
    ("WebLibreWidget", "MellowWidget"),
    ("weblibre_", "mellow_"),
    # ...except this one. `weblibre_settings` is the SyncDocumentKind wire
    # value: it names the document inside settings exports and synced settings
    # records, so it has to survive the rename that moved everything around it.
    ("'mellow_settings'", "'weblibre_settings'"),
    # --- Schemes, file extensions and other stored names ----------------
    ('android:scheme="weblibre"', 'android:scheme="mellow"'),
    ('scheme == "weblibre"', 'scheme == "mellow"'),
    ("weblibre://", "mellow://"),
    # The backup archive extension, anchored so it cannot eat a hostname:
    # it only ever appears at the end of a quoted name or a regex.
    (".weblibre'", ".mellow'"),
    ('.weblibre"', '.mellow"'),
    (".weblibre$", ".mellow$"),
    ('"fontName": "WebLibre"', '"fontName": "Mellow"'),
]

# Files whose content deliberately names upstream's identifiers and must not be
# rewritten: they are about the fork's relationship to WebLibre, not code.
EXCLUDED_PATHS = frozenset(
    {
        "NOTICE",
        "README.md",
        "docs/CHANGES-FROM-WEBLIBRE.md",
        "docs/WEBLIBRE-CHANGELOG.md",
    }
)


def rewrite(text: str) -> str:
    """Apply every rename to a blob of text."""
    for old, new in RENAMES:
        text = text.replace(old, new)
    return text


def main() -> int:
    sys.stdout.write(rewrite(sys.stdin.read()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
