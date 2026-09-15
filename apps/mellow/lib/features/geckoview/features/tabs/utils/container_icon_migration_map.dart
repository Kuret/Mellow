/*
 * Copyright (c) 2024-2026 Fabian Freund.
 *
 * This file is part of WebLibre
 * (see https://weblibre.eu).
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

/// Maps a legacy `ContainerMetadata.iconData` MDI code point (v17 and
/// earlier, `IconDataJsonConverter`) to a Firefox contextual-identity icon
/// keyword (`FirefoxContainerIcon`, v18+), for the one-shot `container` data
/// backfill in the `from17To18` tabs-database migration.
///
/// The old container icon picker offered every Material Design Icon (there
/// was no curated list; `ContainerIconPickerSheet` iterated `MdiIcons.values`
/// with a search box), so this table cannot be exhaustive. It covers the
/// icons named in the migration design as representative of each Firefox
/// icon's semantic bucket (see `plans/DESIGN.md` "Backfill (migration
/// 18->19)"); anything not listed here falls back to `circle`, matching how
/// `FirefoxContainerIcon.fromKeyword` already treats unknown keywords.
///
/// Each entry is keyed by the exact `IconData.codePoint` MDI emits for that
/// icon (from `flutter_material_design_icons` 3.1.0+7447,
/// `package:flutter_material_design_icons/src/icons.enum.dart`), so it can be
/// audited against the `MdiIcons.<name>` in the trailing comment.
const Map<int, String> _legacyContainerIconCodePoints = {
  0xf00d6: 'briefcase', // MdiIcons.briefcase
  0xf1494: 'briefcase', // MdiIcons.briefcaseVariant
  0xf0110: 'cart', // MdiIcons.cart
  0xf0111: 'cart', // MdiIcons.cartOutline
  0xf049a: 'cart', // MdiIcons.shopping
  0xf0076: 'cart', // MdiIcons.basket
  0xf04dc: 'cart', // MdiIcons.store
  0xf0070: 'dollar', // MdiIcons.bank
  0xf0114: 'dollar', // MdiIcons.cash
  0xf01c1: 'dollar', // MdiIcons.currencyUsd
  0xf0fef: 'dollar', // MdiIcons.creditCard
  0xf0584: 'dollar', // MdiIcons.wallet
  0xf0237: 'fingerprint', // MdiIcons.fingerprint
  0xf0498: 'fingerprint', // MdiIcons.shield
  0xf099d: 'fingerprint', // MdiIcons.shieldLock
  0xf033e: 'fingerprint', // MdiIcons.lock
  0xf0483: 'fingerprint', // MdiIcons.security
  0xf0e44: 'gift', // MdiIcons.gift
  0xf001d: 'vacation', // MdiIcons.airplane
  0xf0092: 'vacation', // MdiIcons.beach
  0xf1055: 'vacation', // MdiIcons.palmTree
  0xf034d: 'vacation', // MdiIcons.map
  0xf018b: 'vacation', // MdiIcons.compass
  0xf025a: 'food', // MdiIcons.food
  0xf04a3: 'food', // MdiIcons.silverware
  0xf0409: 'food', // MdiIcons.pizza
  0xf0176: 'food', // MdiIcons.coffee
  0xf025b: 'fruit', // MdiIcons.foodApple
  0xf1043: 'fruit', // MdiIcons.fruitCitrus
  0xf03e9: 'pet', // MdiIcons.paw
  0xf0a43: 'pet', // MdiIcons.dog
  0xf011b: 'pet', // MdiIcons.cat
  0xf0531: 'tree', // MdiIcons.tree
  0xf032a: 'tree', // MdiIcons.leaf
  0xf1897: 'tree', // MdiIcons.forest
  0xf02aa: 'chill', // MdiIcons.glasses
  0xf04e0: 'chill', // MdiIcons.sunglasses
  0xf0296: 'chill', // MdiIcons.gamepad
  0xf0387: 'chill', // MdiIcons.musicNote
  0xf0381: 'chill', // MdiIcons.movie
  0xf02dc: 'fence', // MdiIcons.home
  0xf179a: 'fence', // MdiIcons.fence
  0xf0765: 'circle', // MdiIcons.circle
  0xf0004: 'circle', // MdiIcons.account
  0xf04ce: 'circle', // MdiIcons.star
};

/// The Firefox contextual-identity icon keyword for a legacy MDI [codePoint],
/// or `null` if [codePoint] is `null` or not in the migration table (callers
/// should default to `circle` themselves, matching
/// `FirefoxContainerIcon.fromKeyword`'s fallback for unknown keywords).
String? containerIconKeyForLegacyCodePoint(int? codePoint) {
  if (codePoint == null) {
    return null;
  }
  return _legacyContainerIconCodePoints[codePoint];
}
