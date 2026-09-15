// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'container_data.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ContainerDataCWProxy {
  ContainerData id(String id);

  ContainerData syncGuid(String? syncGuid);

  ContainerData name(String name);

  ContainerData iconKey(String iconKey);

  ContainerData colorKey(String colorKey);

  ContainerData orderKey(String orderKey);

  ContainerData isPinned(bool isPinned);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `ContainerData(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ContainerData(...).copyWith(id: 12, name: "My name")
  /// ```
  ContainerData call({
    String id,
    String? syncGuid,
    String name,
    String iconKey,
    String colorKey,
    String orderKey,
    bool isPinned,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfContainerData.copyWith(...)` or call `instanceOfContainerData.copyWith.fieldName(value)` for a single field.
class _$ContainerDataCWProxyImpl implements _$ContainerDataCWProxy {
  const _$ContainerDataCWProxyImpl(this._value);

  final ContainerData _value;

  @override
  ContainerData id(String id) => call(id: id);

  @override
  ContainerData syncGuid(String? syncGuid) => call(syncGuid: syncGuid);

  @override
  ContainerData name(String name) => call(name: name);

  @override
  ContainerData iconKey(String iconKey) => call(iconKey: iconKey);

  @override
  ContainerData colorKey(String colorKey) => call(colorKey: colorKey);

  @override
  ContainerData orderKey(String orderKey) => call(orderKey: orderKey);

  @override
  ContainerData isPinned(bool isPinned) => call(isPinned: isPinned);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `ContainerData(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ContainerData(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ContainerData call({
    Object? id = const $CopyWithPlaceholder(),
    Object? syncGuid = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? iconKey = const $CopyWithPlaceholder(),
    Object? colorKey = const $CopyWithPlaceholder(),
    Object? orderKey = const $CopyWithPlaceholder(),
    Object? isPinned = const $CopyWithPlaceholder(),
  }) {
    return ContainerData(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      syncGuid: syncGuid == const $CopyWithPlaceholder()
          ? _value.syncGuid
          // ignore: cast_nullable_to_non_nullable
          : syncGuid as String?,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      iconKey: iconKey == const $CopyWithPlaceholder() || iconKey == null
          ? _value.iconKey
          // ignore: cast_nullable_to_non_nullable
          : iconKey as String,
      colorKey: colorKey == const $CopyWithPlaceholder() || colorKey == null
          ? _value.colorKey
          // ignore: cast_nullable_to_non_nullable
          : colorKey as String,
      orderKey: orderKey == const $CopyWithPlaceholder() || orderKey == null
          ? _value.orderKey
          // ignore: cast_nullable_to_non_nullable
          : orderKey as String,
      isPinned: isPinned == const $CopyWithPlaceholder() || isPinned == null
          ? _value.isPinned
          // ignore: cast_nullable_to_non_nullable
          : isPinned as bool,
    );
  }
}

extension $ContainerDataCopyWith on ContainerData {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfContainerData.copyWith(...)` or `instanceOfContainerData.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ContainerDataCWProxy get copyWith => _$ContainerDataCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContainerData _$ContainerDataFromJson(Map<String, dynamic> json) =>
    ContainerData(
      id: json['id'] as String,
      syncGuid: json['syncGuid'] as String?,
      name: json['name'] as String? ?? '',
      iconKey: json['iconKey'] as String? ?? 'circle',
      colorKey: json['colorKey'] as String? ?? 'blue',
      orderKey: json['orderKey'] as String,
      isPinned: json['isPinned'] as bool? ?? false,
    );

Map<String, dynamic> _$ContainerDataToJson(ContainerData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'syncGuid': instance.syncGuid,
      'name': instance.name,
      'iconKey': instance.iconKey,
      'colorKey': instance.colorKey,
      'orderKey': instance.orderKey,
      'isPinned': instance.isPinned,
    };

ContainerDataWithCount _$ContainerDataWithCountFromJson(
  Map<String, dynamic> json,
) => ContainerDataWithCount(
  id: json['id'] as String,
  syncGuid: json['syncGuid'] as String?,
  name: json['name'] as String? ?? '',
  iconKey: json['iconKey'] as String? ?? 'circle',
  colorKey: json['colorKey'] as String? ?? 'blue',
  orderKey: json['orderKey'] as String,
  isPinned: json['isPinned'] as bool? ?? false,
  tabCount: (json['tabCount'] as num?)?.toInt(),
);

Map<String, dynamic> _$ContainerDataWithCountToJson(
  ContainerDataWithCount instance,
) => <String, dynamic>{
  'id': instance.id,
  'syncGuid': instance.syncGuid,
  'name': instance.name,
  'iconKey': instance.iconKey,
  'colorKey': instance.colorKey,
  'orderKey': instance.orderKey,
  'isPinned': instance.isPinned,
  'tabCount': instance.tabCount,
};
