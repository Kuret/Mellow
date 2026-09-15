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
import 'package:flutter/material.dart';
import 'package:weblibre/features/search/domain/entities/search_provider.dart';
import 'package:weblibre/presentation/widgets/url_icon.dart';

/// The engine's favicon, fetched from its own home page.
///
/// A wrapper rather than a raw [UrlIcon] so every provider affordance — the
/// address-bar prefix, the settings tile, the picker rows — asks for the icon
/// the same way and at whatever size its caller needs.
class SearchProviderIcon extends StatelessWidget {
  final SearchProvider provider;
  final double iconSize;

  const SearchProviderIcon({
    required this.provider,
    this.iconSize = 20,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return UrlIcon([provider.homeUrl], iconSize: iconSize);
  }
}
