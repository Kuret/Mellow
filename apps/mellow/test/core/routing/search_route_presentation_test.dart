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
import 'package:weblibre/core/routing/routes.dart';
import 'package:weblibre/features/geckoview/features/search/domain/entities/search_presentation.dart';

void main() {
  group('SearchRoute presentation', () {
    test('floats over the page by default', () {
      expect(
        const SearchRoute(tabType: TabType.regular).effectivePresentation,
        SearchPresentation.panel,
      );
    });

    test('takes the screen when launched from an intent', () {
      // Nothing is behind the search in that case, so there is nothing to
      // float over.
      expect(
        const SearchRoute(
          tabType: TabType.regular,
          launchedFromIntent: true,
        ).effectivePresentation,
        SearchPresentation.fullScreen,
      );
    });

    test('takes the screen when the search is auto-submitted', () {
      // It lands on a page of web results rather than a suggestion list.
      expect(
        const SearchRoute(
          tabType: TabType.regular,
          searchText: 'weblibre',
          autoSubmitSearch: true,
        ).effectivePresentation,
        SearchPresentation.fullScreen,
      );
    });

    test('honours an explicit full-screen request', () {
      expect(
        const SearchRoute(
          tabType: TabType.regular,
          presentation: SearchPresentation.fullScreen,
        ).effectivePresentation,
        SearchPresentation.fullScreen,
      );
    });

    test('keeps the panel out of the location when it is the default', () {
      expect(
        const SearchRoute(tabType: TabType.regular).location,
        isNot(contains('presentation')),
      );
      expect(
        const SearchRoute(
          tabType: TabType.regular,
          presentation: SearchPresentation.fullScreen,
        ).location,
        contains('presentation=full-screen'),
      );
    });
  });
}
