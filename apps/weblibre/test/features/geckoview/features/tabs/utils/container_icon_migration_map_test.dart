import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weblibre/features/geckoview/features/tabs/utils/container_icon_migration_map.dart';

void main() {
  group('containerIconKeyForLegacyCodePoint', () {
    test('maps briefcase-family icons to briefcase', () {
      expect(
        containerIconKeyForLegacyCodePoint(MdiIcons.briefcase.codePoint),
        'briefcase',
      );
      expect(
        containerIconKeyForLegacyCodePoint(MdiIcons.briefcaseVariant.codePoint),
        'briefcase',
      );
    });

    test('maps shopping-family icons to cart', () {
      expect(containerIconKeyForLegacyCodePoint(MdiIcons.cart.codePoint), 'cart');
      expect(
        containerIconKeyForLegacyCodePoint(MdiIcons.store.codePoint),
        'cart',
      );
    });

    test('maps money-family icons to dollar', () {
      expect(
        containerIconKeyForLegacyCodePoint(MdiIcons.wallet.codePoint),
        'dollar',
      );
    });

    test('maps pet-family icons to pet', () {
      expect(containerIconKeyForLegacyCodePoint(MdiIcons.dog.codePoint), 'pet');
      expect(containerIconKeyForLegacyCodePoint(MdiIcons.cat.codePoint), 'pet');
    });

    test('returns null for null input', () {
      expect(containerIconKeyForLegacyCodePoint(null), isNull);
    });

    test('returns null for an unmapped code point', () {
      expect(
        containerIconKeyForLegacyCodePoint(MdiIcons.folderOutline.codePoint),
        isNull,
      );
    });
  });
}
