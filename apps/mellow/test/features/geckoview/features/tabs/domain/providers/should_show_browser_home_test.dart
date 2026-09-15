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
import 'package:flutter_test/flutter_test.dart';
import 'package:mellow/features/geckoview/domain/providers/selected_tab.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/selected_container.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/selected_space.dart';
import 'package:riverpod/riverpod.dart';

const _spaceA = 'space-a';
const _spaceB = 'space-b';

class _FixedSelectedTab extends SelectedTab {
  @override
  String? build() => 'tab-1';
}

/// [SelectedSpace] a test can move directly, standing in for the state
/// change that a real space switch (rail tap, swipe, ...) produces.
class _MutableSelectedSpace extends SelectedSpace {
  @override
  String? build() => _spaceA;

  // ignore: use_setters_to_change_properties
  void moveTo(String spaceUuid) => state = spaceUuid;
}

ProviderContainer _openContainer() {
  final container = ProviderContainer(
    overrides: [
      selectedTabProvider.overrideWith(_FixedSelectedTab.new),
      selectedSpaceProvider.overrideWith(_MutableSelectedSpace.new),
      // The tab's own space never moves in this test: only the selected
      // space does, which is what a restore-in-flight has to ride out.
      selectedTabSpaceUuidProvider.overrideWith((ref) => Stream.value(_spaceA)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('shows the tab when its space matches the selected space', () async {
    final container = _openContainer();
    container.listen(shouldShowBrowserHomeProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);

    expect(container.read(shouldShowBrowserHomeProvider), isFalse);
  });

  test('holds its previous answer instead of flashing home while a restore is '
      'in flight, then re-evaluates once it settles', () async {
    final container = _openContainer();
    container.listen(shouldShowBrowserHomeProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(container.read(shouldShowBrowserHomeProvider), isFalse);

    container.read(restoringSpaceTabProvider.notifier).start();
    // The selected space moves out from under the tab, as it does the
    // instant a swipe lands and before the restore's DB reads settle.
    (container.read(selectedSpaceProvider.notifier) as _MutableSelectedSpace)
        .moveTo(_spaceB);

    // Without the guard this would already read true (mismatch).
    expect(container.read(shouldShowBrowserHomeProvider), isFalse);

    container.read(restoringSpaceTabProvider.notifier).finish();

    expect(container.read(shouldShowBrowserHomeProvider), isTrue);
  });
}
