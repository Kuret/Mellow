import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weblibre/features/geckoview/features/tabs/data/models/container_data.dart';

void main() {
  group('ContainerMetadata icon serialization', () {
    test('stores MDI icon names', () {
      final metadata = ContainerMetadata.withDefaults(
        iconData: MdiIcons.folderOutline,
      );

      final json = metadata.toJson();
      final restored = ContainerMetadata.fromJson(json);

      expect(json['iconData'], <String, dynamic>{'name': 'folder-outline'});
      expect(restored.iconData, MdiIcons.folderOutline);
    });

    test('restores legacy code point JSON as a const MDI icon', () {
      final restored = ContainerMetadata.fromJson({
        'iconData': <String, dynamic>{
          'codePoint': MdiIcons.folderOutline.codePoint,
          'fontFamily': MdiIcons.folderOutline.fontFamily,
          'fontPackage': MdiIcons.folderOutline.fontPackage,
        },
      });

      expect(identical(restored.iconData, MdiIcons.folderOutline), isTrue);
    });
  });
}
