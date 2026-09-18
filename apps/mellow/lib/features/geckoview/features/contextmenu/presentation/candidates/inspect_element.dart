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
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/features/geckoview/domain/providers/selected_tab.dart';
import 'package:mellow/features/geckoview/features/web_inspector/domain/providers/web_inspector.dart';

/// Opens the on-device inspector from the page's context menu, where a desktop
/// browser puts it.
///
/// It arms the element picker rather than jumping straight to the node under
/// the pointer: the hit result the context menu was built from describes a
/// link, image or media source, not a DOM node the inspector could be handed.
/// The next tap picks the element, which is one tap more than a desktop
/// browser needs and still far less than reaching for the menu.
class InspectElement extends ConsumerWidget {
  const InspectElement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTabId = ref.watch(selectedTabProvider);

    return ListTile(
      leading: const Icon(MdiIcons.selectSearch),
      title: const Text('Inspect element'),
      enabled: selectedTabId != null,
      onTap: () {
        if (selectedTabId == null) return;

        unawaited(
          ref
              .read(webInspectorServiceProvider(tabId: selectedTabId))
              .pickElement(),
        );
        Navigator.of(context).pop();
      },
    );
  }
}
