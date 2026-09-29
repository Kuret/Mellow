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
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/features/geckoview/domain/entities/states/history.dart';
import 'package:mellow/features/geckoview/domain/entities/states/tab.dart';
import 'package:mellow/features/geckoview/domain/providers/selected_tab.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_detail_state.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_state.dart';
import 'package:mellow/features/geckoview/features/contextmenu/presentation/page_context_menu_dialog.dart';

const _selectedTabId = 'tab-1';

/// The real provider listens for the native engine to report ready, which
/// this suite never simulates: standing in with a fixed id lets the dialog
/// build without waiting that out, while still giving it a tab to read
/// history state for.
class _FixedSelectedTab extends SelectedTab {
  @override
  String? build() => _selectedTabId;
}

/// Stands in for the per-tab history state Gecko reports, so the dialog's
/// Back/Forward items can be pinned to a known [HistoryState] instead of
/// whatever the (absent, in this suite) native engine would report.
class _FakeTabHistoryStates extends TabHistoryStates {
  _FakeTabHistoryStates(this._history);

  final HistoryState _history;

  @override
  Map<String, HistoryState> build() => {_selectedTabId: _history};
}

/// The real [TabStates] listens for native tab content events and, through
/// them, the engine-ready listener the other fakes here are avoiding: the
/// dialog only reads a tab's URL from this, which no test in this file
/// checks, so an empty map is enough to keep it from reaching any of that.
class _FakeTabStates extends TabStates {
  @override
  Map<String, TabState> build() => const {};
}

void main() {
  /// Opens the dialog the same way [PageContextMenuTrigger] does — a
  /// `showDialog` — with [history] backing the tab it acts on.
  Future<void> pumpDialog(WidgetTester tester, HistoryState history) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedTabProvider.overrideWith(_FixedSelectedTab.new),
          tabHistoryStatesProvider.overrideWith(
            () => _FakeTabHistoryStates(history),
          ),
          tabStatesProvider.overrideWith(_FakeTabStates.new),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) =>
                        const PageContextMenuDialog(anchor: Offset(50, 60)),
                  ),
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    // Not pumpAndSettle: some of the menu's own actions never settle under
    // test. The dialog's 150ms open transition is all that matters here.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  ListTile findItem(WidgetTester tester, String title) =>
      tester.widget<ListTile>(find.widgetWithText(ListTile, title));

  testWidgets(
    'disables Back and Forward when the tab has no history either way',
    (tester) async {
      await pumpDialog(
        tester,
        HistoryState(
          items: const [],
          currentIndex: 0,
          canGoBack: false,
          canGoForward: false,
        ),
      );

      expect(findItem(tester, 'Back').enabled, isFalse);
      expect(findItem(tester, 'Forward').enabled, isFalse);
    },
  );

  testWidgets(
    'enables Back and Forward when the tab has history in both directions',
    (tester) async {
      await pumpDialog(
        tester,
        HistoryState(
          items: const [],
          currentIndex: 1,
          canGoBack: true,
          canGoForward: true,
        ),
      );

      expect(findItem(tester, 'Back').enabled, isTrue);
      expect(findItem(tester, 'Forward').enabled, isTrue);
    },
  );
}
