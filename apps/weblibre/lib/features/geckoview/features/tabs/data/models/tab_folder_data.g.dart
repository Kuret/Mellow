// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tab_folder_data.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TabFolderDataCWProxy {
  TabFolderData id(String id);

  TabFolderData name(String name);

  TabFolderData icon(String? icon);

  TabFolderData spaceUuid(String? spaceUuid);

  TabFolderData parentFolderId(String? parentFolderId);

  TabFolderData live(String? live);

  TabFolderData isCollapsed(bool isCollapsed);

  TabFolderData orderKey(String orderKey);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `TabFolderData(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TabFolderData(...).copyWith(id: 12, name: "My name")
  /// ```
  TabFolderData call({
    String id,
    String name,
    String? icon,
    String? spaceUuid,
    String? parentFolderId,
    String? live,
    bool isCollapsed,
    String orderKey,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTabFolderData.copyWith(...)` or call `instanceOfTabFolderData.copyWith.fieldName(value)` for a single field.
class _$TabFolderDataCWProxyImpl implements _$TabFolderDataCWProxy {
  const _$TabFolderDataCWProxyImpl(this._value);

  final TabFolderData _value;

  @override
  TabFolderData id(String id) => call(id: id);

  @override
  TabFolderData name(String name) => call(name: name);

  @override
  TabFolderData icon(String? icon) => call(icon: icon);

  @override
  TabFolderData spaceUuid(String? spaceUuid) => call(spaceUuid: spaceUuid);

  @override
  TabFolderData parentFolderId(String? parentFolderId) =>
      call(parentFolderId: parentFolderId);

  @override
  TabFolderData live(String? live) => call(live: live);

  @override
  TabFolderData isCollapsed(bool isCollapsed) => call(isCollapsed: isCollapsed);

  @override
  TabFolderData orderKey(String orderKey) => call(orderKey: orderKey);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `TabFolderData(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TabFolderData(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TabFolderData call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? icon = const $CopyWithPlaceholder(),
    Object? spaceUuid = const $CopyWithPlaceholder(),
    Object? parentFolderId = const $CopyWithPlaceholder(),
    Object? live = const $CopyWithPlaceholder(),
    Object? isCollapsed = const $CopyWithPlaceholder(),
    Object? orderKey = const $CopyWithPlaceholder(),
  }) {
    return TabFolderData(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      icon: icon == const $CopyWithPlaceholder()
          ? _value.icon
          // ignore: cast_nullable_to_non_nullable
          : icon as String?,
      spaceUuid: spaceUuid == const $CopyWithPlaceholder()
          ? _value.spaceUuid
          // ignore: cast_nullable_to_non_nullable
          : spaceUuid as String?,
      parentFolderId: parentFolderId == const $CopyWithPlaceholder()
          ? _value.parentFolderId
          // ignore: cast_nullable_to_non_nullable
          : parentFolderId as String?,
      live: live == const $CopyWithPlaceholder()
          ? _value.live
          // ignore: cast_nullable_to_non_nullable
          : live as String?,
      isCollapsed:
          isCollapsed == const $CopyWithPlaceholder() || isCollapsed == null
          ? _value.isCollapsed
          // ignore: cast_nullable_to_non_nullable
          : isCollapsed as bool,
      orderKey: orderKey == const $CopyWithPlaceholder() || orderKey == null
          ? _value.orderKey
          // ignore: cast_nullable_to_non_nullable
          : orderKey as String,
    );
  }
}

extension $TabFolderDataCopyWith on TabFolderData {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTabFolderData.copyWith(...)` or `instanceOfTabFolderData.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TabFolderDataCWProxy get copyWith => _$TabFolderDataCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TabFolderData _$TabFolderDataFromJson(Map<String, dynamic> json) =>
    TabFolderData(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String?,
      spaceUuid: json['spaceUuid'] as String?,
      parentFolderId: json['parentFolderId'] as String?,
      live: json['live'] as String?,
      isCollapsed: json['isCollapsed'] as bool? ?? false,
      orderKey: json['orderKey'] as String,
    );

Map<String, dynamic> _$TabFolderDataToJson(TabFolderData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'spaceUuid': instance.spaceUuid,
      'parentFolderId': instance.parentFolderId,
      'live': instance.live,
      'isCollapsed': instance.isCollapsed,
      'orderKey': instance.orderKey,
    };
