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
import 'package:mellow/features/geckoview/features/browser/domain/providers.dart';
import 'package:mellow/features/search/domain/entities/builtin_search_providers.dart';
import 'package:mellow/features/search/domain/entities/custom_search_providers.dart';
import 'package:mellow/features/search/domain/providers/search_provider.dart';
import 'package:mellow/features/user/data/models/general_settings.dart';
import 'package:mellow/features/user/data/models/zen_settings.dart';
import 'package:mellow/features/user/domain/repositories/general_settings.dart';
import 'package:mellow/features/user/domain/repositories/zen_settings.dart';
import 'package:riverpod/riverpod.dart';

final _searx = CustomSearchEngine(
  id: 'custom:searx',
  name: 'Searx',
  urlTemplate: 'https://searx.be/search?q={searchTerms}',
);

ProviderContainer _container({
  String? defaultProviderId,
  List<CustomSearchEngine> engines = const [],
}) {
  final container = ProviderContainer(
    overrides: [
      generalSettingsWithDefaultsProvider.overrideWith(
        (ref) => GeneralSettings.withDefaults(
          defaultSearchProvider: defaultProviderId,
        ),
      ),
      zenSettingsWithDefaultsProvider.overrideWith(
        (ref) => ZenSettings.withDefaults(customSearchProviders: engines),
      ),
    ],
  );

  addTearDown(container.dispose);

  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('allSearchProviders', () {
    test('is the built-ins alone when the user added nothing', () {
      final container = _container();

      expect(
        container.read(allSearchProvidersProvider),
        builtinSearchProviders,
      );
    });

    test('lists the user engines after the built-ins', () {
      final container = _container(engines: [_searx]);

      final all = container.read(allSearchProvidersProvider);

      expect(all, hasLength(builtinSearchProviders.length + 1));
      expect(all.take(builtinSearchProviders.length), builtinSearchProviders);
      expect(all.last.id, _searx.id);
      expect(all.last.name, 'Searx');
      expect(all.last.iconHost, 'searx.be');
    });
  });

  group('searchProviderById', () {
    test('finds a built-in and a custom engine alike', () {
      final container = _container(engines: [_searx]);

      expect(
        container.read(searchProviderByIdProvider('duckduckgo'))?.name,
        'DuckDuckGo',
      );
      expect(
        container.read(searchProviderByIdProvider(_searx.id))?.name,
        'Searx',
      );
    });

    test('has nothing for an id no engine carries', () {
      final container = _container();

      expect(container.read(searchProviderByIdProvider('custom:gone')), isNull);
      expect(container.read(searchProviderByIdProvider(null)), isNull);
    });
  });

  group('defaultSearchProvider', () {
    test('resolves a built-in id', () {
      final container = _container(defaultProviderId: 'kagi');

      expect(container.read(defaultSearchProviderProvider).id, 'kagi');
    });

    test('resolves a custom id', () {
      final container = _container(
        defaultProviderId: _searx.id,
        engines: [_searx],
      );

      final provider = container.read(defaultSearchProviderProvider);

      expect(provider.id, _searx.id);
      expect(
        provider.searchUrl('cats').toString(),
        'https://searx.be/search?q=cats',
      );
    });

    // Deleting the engine that is the default must leave the browser
    // searchable. The stored id outlives the engine, so resolution has to treat
    // a dangling id as "nothing we have" rather than as a reason to fail.
    test('falls back when the custom default has been deleted', () {
      final container = _container(defaultProviderId: _searx.id);

      final provider = container.read(defaultSearchProviderProvider);

      expect(provider, fallbackSearchProvider);
      expect(provider.searchUrl('cats').host, isNotEmpty);
    });

    // The same engine, deleted while the browser is running rather than absent
    // from the start: the resolution has to come apart on the settings change,
    // not only on a cold read.
    test('falls back the moment the engine is deleted', () {
      var engines = [_searx];
      final container = ProviderContainer(
        overrides: [
          generalSettingsWithDefaultsProvider.overrideWith(
            (ref) =>
                GeneralSettings.withDefaults(defaultSearchProvider: _searx.id),
          ),
          zenSettingsWithDefaultsProvider.overrideWith(
            (ref) => ZenSettings.withDefaults(customSearchProviders: engines),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(defaultSearchProviderProvider).id, _searx.id);

      engines = [];
      container.invalidate(zenSettingsWithDefaultsProvider);

      expect(
        container.read(defaultSearchProviderProvider),
        fallbackSearchProvider,
      );
    });
  });

  // The per-search override is held in memory rather than resolved from the
  // catalogue on every read, so deleting the engine it names used to keep
  // sending searches to it until the app restarted — the standing default fell
  // back, the override did not.
  group('selectedSearchProvider', () {
    test('drops an override whose engine has been deleted', () {
      var engines = [_searx];
      final container = ProviderContainer(
        overrides: [
          generalSettingsWithDefaultsProvider.overrideWith(
            (ref) => GeneralSettings.withDefaults(),
          ),
          zenSettingsWithDefaultsProvider.overrideWith(
            (ref) => ZenSettings.withDefaults(customSearchProviders: engines),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        selectedSearchProviderProvider().notifier,
      );
      notifier.select(customSearchProvider(_searx));

      expect(container.read(selectedSearchProviderProvider())?.id, _searx.id);

      engines = [];
      container.invalidate(zenSettingsWithDefaultsProvider);
      container.read(allSearchProvidersProvider);

      expect(container.read(selectedSearchProviderProvider()), isNull);
    });

    test('leaves an override whose engine is still there alone', () {
      final container = _container(engines: [_searx]);

      container
          .read(selectedSearchProviderProvider().notifier)
          .select(customSearchProvider(_searx));

      container.invalidate(zenSettingsWithDefaultsProvider);
      container.read(allSearchProvidersProvider);

      expect(container.read(selectedSearchProviderProvider())?.id, _searx.id);
    });
  });
}
