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
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart' show IconData;
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

/// Firefox's fixed contextual-identity colour vocabulary. Zen's `container`
/// record carries one of these keywords (or `""`), never an ARGB value, so the
/// row stores the keyword raw and this enum only interprets it for display.
///
/// ARGB values are Firefox's `identity-color-*` swatches. [toolbar] has no
/// colour of its own and follows the theme.
enum FirefoxContainerColor {
  blue('blue', 0xFF37ADFF),
  turquoise('turquoise', 0xFF00C79A),
  green('green', 0xFF51CD00),
  yellow('yellow', 0xFFFFCB00),
  orange('orange', 0xFFFF9F00),
  red('red', 0xFFFF613D),
  pink('pink', 0xFFFF4BDA),
  purple('purple', 0xFFAF51F5),
  toolbar('toolbar', null);

  const FirefoxContainerColor(this.keyword, this.argb);

  final String keyword;
  final int? argb;

  Color? get color => argb == null ? null : Color(argb!);

  /// Unknown or empty keywords render as [toolbar]; the raw keyword must still
  /// be re-emitted unchanged on the wire.
  static FirefoxContainerColor fromKeyword(String? keyword) {
    for (final value in values) {
      if (value.keyword == keyword) return value;
    }
    return toolbar;
  }

  /// The coloured keyword closest to [argb] in RGB space. Deterministic, so
  /// the same legacy colour maps identically on every device (PLAN §7.2).
  static FirefoxContainerColor nearestTo(int argb) {
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    FirefoxContainerColor best = blue;
    var bestDistance = double.infinity;
    for (final value in values) {
      final candidate = value.argb;
      if (candidate == null) continue;
      final dr = r - ((candidate >> 16) & 0xFF);
      final dg = g - ((candidate >> 8) & 0xFF);
      final db = b - (candidate & 0xFF);
      final distance = math.sqrt((dr * dr + dg * dg + db * db).toDouble());
      if (distance < bestDistance) {
        bestDistance = distance;
        best = value;
      }
    }
    return best;
  }
}

/// Firefox's fixed contextual-identity icon vocabulary, rendered with the
/// closest Material Design icon.
enum FirefoxContainerIcon {
  fingerprint('fingerprint'),
  briefcase('briefcase'),
  dollar('dollar'),
  cart('cart'),
  circle('circle'),
  gift('gift'),
  vacation('vacation'),
  food('food'),
  fruit('fruit'),
  pet('pet'),
  tree('tree'),
  chill('chill'),
  fence('fence');

  const FirefoxContainerIcon(this.keyword);

  final String keyword;

  IconData get icon => switch (this) {
    fingerprint => MdiIcons.fingerprint,
    briefcase => MdiIcons.briefcase,
    dollar => MdiIcons.currencyUsd,
    cart => MdiIcons.cart,
    circle => MdiIcons.circle,
    gift => MdiIcons.gift,
    vacation => MdiIcons.palmTree,
    food => MdiIcons.food,
    fruit => MdiIcons.foodApple,
    pet => MdiIcons.paw,
    tree => MdiIcons.tree,
    chill => MdiIcons.sunglasses,
    fence => MdiIcons.fence,
  };

  /// Unknown or empty keywords render as [circle]; the raw keyword must still
  /// be re-emitted unchanged on the wire.
  static FirefoxContainerIcon fromKeyword(String? keyword) {
    for (final value in values) {
      if (value.keyword == keyword) return value;
    }
    return circle;
  }
}

/// Firefox's four built-in identities, keyed by Zen's well-known guids
/// (`builtin-1`..`builtin-4`). Created locally on demand when the desktop
/// references one; never projected (DESIGN.md "D3 refinement").
enum FirefoxBuiltinContainer {
  personal(
    1,
    'Personal',
    FirefoxContainerIcon.fingerprint,
    FirefoxContainerColor.blue,
  ),
  work(2, 'Work', FirefoxContainerIcon.briefcase, FirefoxContainerColor.orange),
  banking(
    3,
    'Banking',
    FirefoxContainerIcon.dollar,
    FirefoxContainerColor.green,
  ),
  shopping(
    4,
    'Shopping',
    FirefoxContainerIcon.cart,
    FirefoxContainerColor.pink,
  );

  const FirefoxBuiltinContainer(
    this.userContextId,
    this.name,
    this.icon,
    this.color,
  );

  final int userContextId;
  final String name;
  final FirefoxContainerIcon icon;
  final FirefoxContainerColor color;

  String get syncGuid => 'builtin-$userContextId';

  static FirefoxBuiltinContainer? fromSyncGuid(String? guid) {
    for (final value in values) {
      if (value.syncGuid == guid) return value;
    }
    return null;
  }
}
