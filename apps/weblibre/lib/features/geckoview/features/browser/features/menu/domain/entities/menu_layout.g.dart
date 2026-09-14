// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_layout.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MenuItemEntry _$MenuItemEntryFromJson(Map<String, dynamic> json) =>
    MenuItemEntry(
      type: $enumDecode(_$MenuItemTypeEnumMap, json['type']),
      visible: json['visible'] as bool,
      items: json['items'] == null
          ? const []
          : menuItemEntriesFromJson(json['items']),
    );

Map<String, dynamic> _$MenuItemEntryToJson(MenuItemEntry instance) =>
    <String, dynamic>{
      'type': _$MenuItemTypeEnumMap[instance.type]!,
      'visible': instance.visible,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

const _$MenuItemTypeEnumMap = {
  MenuItemType.desktopMode: 'desktopMode',
  MenuItemType.addBookmark: 'addBookmark',
  MenuItemType.findInPage: 'findInPage',
  MenuItemType.inspectElement: 'inspectElement',
  MenuItemType.addToHomeScreen: 'addToHomeScreen',
  MenuItemType.openInApp: 'openInApp',
  MenuItemType.containers: 'containers',
  MenuItemType.manageContainers: 'manageContainers',
  MenuItemType.assignContainer: 'assignContainer',
  MenuItemType.unassignContainer: 'unassignContainer',
  MenuItemType.share: 'share',
  MenuItemType.copyAddress: 'copyAddress',
  MenuItemType.shareScreenshot: 'shareScreenshot',
  MenuItemType.shareLink: 'shareLink',
  MenuItemType.sendToDevice: 'sendToDevice',
  MenuItemType.showQrCode: 'showQrCode',
  MenuItemType.moreDisclosure: 'moreDisclosure',
  MenuItemType.cloneTab: 'cloneTab',
  MenuItemType.cloneRegularTab: 'cloneRegularTab',
  MenuItemType.clonePrivateTab: 'clonePrivateTab',
  MenuItemType.export: 'export',
  MenuItemType.copyAsMarkdown: 'copyAsMarkdown',
  MenuItemType.exportAsMarkdown: 'exportAsMarkdown',
  MenuItemType.exportAsPdf: 'exportAsPdf',
  MenuItemType.exportAsPng: 'exportAsPng',
  MenuItemType.printPage: 'printPage',
  MenuItemType.history: 'history',
  MenuItemType.bookmarks: 'bookmarks',
  MenuItemType.downloads: 'downloads',
  MenuItemType.setDefaultBrowser: 'setDefaultBrowser',
  MenuItemType.profileSwitch: 'profileSwitch',
  MenuItemType.syncNow: 'syncNow',
  MenuItemType.appSettings: 'appSettings',
  MenuItemType.quitBrowser: 'quitBrowser',
  MenuItemType.about: 'about',
};

MenuSectionEntry _$MenuSectionEntryFromJson(Map<String, dynamic> json) =>
    MenuSectionEntry(
      type: $enumDecode(_$MenuSectionTypeEnumMap, json['type']),
      visible: json['visible'] as bool,
      items: json['items'] == null
          ? const []
          : menuItemEntriesFromJson(json['items']),
    );

Map<String, dynamic> _$MenuSectionEntryToJson(MenuSectionEntry instance) =>
    <String, dynamic>{
      'type': _$MenuSectionTypeEnumMap[instance.type]!,
      'visible': instance.visible,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

const _$MenuSectionTypeEnumMap = {
  MenuSectionType.pageActions: 'pageActions',
  MenuSectionType.extensions: 'extensions',
  MenuSectionType.tabActions: 'tabActions',
  MenuSectionType.quickLinks: 'quickLinks',
  MenuSectionType.profile: 'profile',
  MenuSectionType.about: 'about',
};
