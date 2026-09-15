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
import 'package:mellow/features/geckoview/features/tabs/domain/providers/space_last_tab.dart';
import 'package:mellow/features/user/data/providers.dart';
import 'package:riverpod/experimental/persist.dart';
import 'package:riverpod/riverpod.dart';

ProviderContainer _openContainer() {
  final container = ProviderContainer(
    overrides: [
      riverpodDatabaseStorageProvider.overrideWithValue(
        Storage<String, String>.inMemory(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('a space with no recorded entry has none', () async {
    final container = _openContainer();
    final entry = await container
        .read(spaceLastTabProvider.notifier)
        .entryFor('space-1');
    expect(entry, isNull);
  });

  test('recording a tab makes it the entry for its space', () async {
    final container = _openContainer();
    final notifier = container.read(spaceLastTabProvider.notifier);
    await notifier.recordTab('space-1', 'tab-1');

    final entry = await notifier.entryFor('space-1');
    expect(entry, isA<SpaceLastTabTab>());
    expect((entry! as SpaceLastTabTab).tabId, 'tab-1');
  });

  test('recording a later tab overwrites the earlier one', () async {
    final container = _openContainer();
    final notifier = container.read(spaceLastTabProvider.notifier);
    await notifier.recordTab('space-1', 'tab-1');
    await notifier.recordTab('space-1', 'tab-2');

    final entry = await notifier.entryFor('space-1');
    expect((entry! as SpaceLastTabTab).tabId, 'tab-2');
  });

  test('recording home is a distinct entry from no entry at all', () async {
    final container = _openContainer();
    final notifier = container.read(spaceLastTabProvider.notifier);
    await notifier.recordHome('space-1');

    final entry = await notifier.entryFor('space-1');
    expect(entry, isA<SpaceLastTabHome>());
  });

  test('recording home overwrites a previously recorded tab', () async {
    final container = _openContainer();
    final notifier = container.read(spaceLastTabProvider.notifier);
    await notifier.recordTab('space-1', 'tab-1');
    await notifier.recordHome('space-1');

    final entry = await notifier.entryFor('space-1');
    expect(entry, isA<SpaceLastTabHome>());
  });

  test('pruning drops entries for spaces no longer in the valid set', () async {
    final container = _openContainer();
    final notifier = container.read(spaceLastTabProvider.notifier);
    await notifier.recordTab('space-1', 'tab-1');
    await notifier.recordTab('space-2', 'tab-2');

    await notifier.pruneToSpaces({'space-1'});

    expect(await notifier.entryFor('space-1'), isA<SpaceLastTabTab>());
    expect(await notifier.entryFor('space-2'), isNull);
  });

  test(
    'the map survives across a rebuild backed by the same storage',
    () async {
      final storage = Storage<String, String>.inMemory();
      final first = ProviderContainer(
        overrides: [riverpodDatabaseStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(first.dispose);
      await first
          .read(spaceLastTabProvider.notifier)
          .recordTab('space-1', 'tab-1');

      final second = ProviderContainer(
        overrides: [riverpodDatabaseStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(second.dispose);
      final entry = await second
          .read(spaceLastTabProvider.notifier)
          .entryFor('space-1');
      expect((entry! as SpaceLastTabTab).tabId, 'tab-1');
    },
  );
}
