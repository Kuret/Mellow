import 'package:flutter_test/flutter_test.dart';
import 'package:weblibre/core/routing/routes.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/entities/tab_mode.dart';

void main() {
  group('TabMode value semantics', () {
    test('same modes are equal and hash equally', () {
      expect(TabMode.regular, equals(const RegularTabMode()));
      expect(TabMode.regular.hashCode, equals(const RegularTabMode().hashCode));
      expect(TabMode.private, equals(const PrivateTabMode()));
    });

    test('different modes are not equal', () {
      expect(TabMode.regular, isNot(equals(TabMode.private)));
    });

    test('round-trips through the db value', () {
      for (final mode in [TabMode.regular, TabMode.private]) {
        expect(TabMode.fromDbValue(mode.toDbValue()), equals(mode));
      }
      expect(TabModeDbValue.regular.index, 0);
      expect(TabModeDbValue.private.index, 1);
    });

    test('maps to and from TabType', () {
      expect(TabMode.fromTabType(TabType.private), TabMode.private);
      expect(TabMode.fromTabType(TabType.regular), TabMode.regular);
      expect(TabMode.fromTabType(TabType.child), TabMode.regular);
      expect(TabMode.private.toTabType(), TabType.private);
      expect(TabMode.regular.toTabType(), TabType.regular);
    });
  });
}
