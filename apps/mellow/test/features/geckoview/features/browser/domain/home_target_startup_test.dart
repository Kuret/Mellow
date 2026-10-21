import 'package:flutter_mozilla_components/flutter_mozilla_components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/features/geckoview/domain/providers.dart';
import 'package:mellow/features/geckoview/domain/providers/restore_complete.dart';
import 'package:mellow/features/geckoview/domain/providers/selected_tab.dart';
import 'package:mellow/features/geckoview/domain/repositories/tab.dart';
import 'package:mellow/features/geckoview/features/browser/domain/controllers/home_target_controller.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/selected_container.dart';

class _RestoredSession extends BrowserRestoreComplete {
  @override
  bool build() => true;
}

/// The debounced selection event has not arrived, as at the moment restore
/// completes.
class _NoSelectionEventYet extends SelectedTab {
  @override
  String? build() => null;
}

/// Resuming finds nothing, so the home target falls back to home.
class _FakeTabRepository extends TabRepository {
  @override
  void build() {}

  @override
  Future<bool> resumeLatestTab({Set<String> excludedTabIds = const {}}) async =>
      false;
}

/// [ForceBrowserHome] without remembering the space it was left on, which
/// reads the user database.
class _FakeForceBrowserHome extends ForceBrowserHome {
  @override
  void request() => state = true;
}

/// Past the window the controller gives a restored selection to arrive (300ms).
const _pastWindow = Duration(milliseconds: 400);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GeckoEventService events;
  late ProviderContainer container;

  setUp(() {
    events = GeckoEventService.setUp();
    container = ProviderContainer(
      overrides: [
        eventServiceProvider.overrideWithValue(events),
        browserRestoreCompleteProvider.overrideWith(_RestoredSession.new),
        selectedTabProvider.overrideWith(_NoSelectionEventYet.new),
        tabRepositoryProvider.overrideWith(_FakeTabRepository.new),
        forceBrowserHomeProvider.overrideWith(_FakeForceBrowserHome.new),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await events.dispose();
    });
  });

  bool homeForced() => container.read(forceBrowserHomeProvider);

  /// What `TabRepository.selectTab` does in one synchronous step: clears the
  /// home latch and dispatches the selection.
  void pickTab() => container.read(forceBrowserHomeProvider.notifier).clear();

  test('a session with nothing selected gets the home target', () async {
    container.read(homeTargetControllerProvider);
    await Future<void>.delayed(_pastWindow);

    expect(homeForced(), isTrue);
  });

  test(
    'a restored selection that arrives in the window keeps home off',
    () async {
      container.read(homeTargetControllerProvider);
      await pumpEventQueue();

      await events.onSelectedTabChange(1, 'restored');
      await Future<void>.delayed(_pastWindow);

      expect(homeForced(), isFalse);
    },
  );

  test(
    'a tab picked while the window is open is not covered by home',
    () async {
      container.read(homeTargetControllerProvider);
      await pumpEventQueue();

      // The user's selection is dispatched after the window opened, so the
      // window running out empty predates it.
      pickTab();
      await Future<void>.delayed(_pastWindow);
      expect(homeForced(), isFalse, reason: 'the controller waits again');

      await events.onSelectedTabChange(1, 'picked');
      await Future<void>.delayed(_pastWindow);

      expect(homeForced(), isFalse);
    },
  );
}
