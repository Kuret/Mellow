// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'space_data.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SpaceDataCWProxy {
  SpaceData uuid(String uuid);

  SpaceData name(String name);

  SpaceData icon(String? icon);

  SpaceData theme(String? theme);

  SpaceData containerId(String? containerId);

  SpaceData orderIndex(int orderIndex);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `SpaceData(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SpaceData(...).copyWith(id: 12, name: "My name")
  /// ```
  SpaceData call({
    String uuid,
    String name,
    String? icon,
    String? theme,
    String? containerId,
    int orderIndex,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSpaceData.copyWith(...)` or call `instanceOfSpaceData.copyWith.fieldName(value)` for a single field.
class _$SpaceDataCWProxyImpl implements _$SpaceDataCWProxy {
  const _$SpaceDataCWProxyImpl(this._value);

  final SpaceData _value;

  @override
  SpaceData uuid(String uuid) => call(uuid: uuid);

  @override
  SpaceData name(String name) => call(name: name);

  @override
  SpaceData icon(String? icon) => call(icon: icon);

  @override
  SpaceData theme(String? theme) => call(theme: theme);

  @override
  SpaceData containerId(String? containerId) => call(containerId: containerId);

  @override
  SpaceData orderIndex(int orderIndex) => call(orderIndex: orderIndex);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `SpaceData(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SpaceData(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SpaceData call({
    Object? uuid = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? icon = const $CopyWithPlaceholder(),
    Object? theme = const $CopyWithPlaceholder(),
    Object? containerId = const $CopyWithPlaceholder(),
    Object? orderIndex = const $CopyWithPlaceholder(),
  }) {
    return SpaceData(
      uuid: uuid == const $CopyWithPlaceholder() || uuid == null
          ? _value.uuid
          // ignore: cast_nullable_to_non_nullable
          : uuid as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      icon: icon == const $CopyWithPlaceholder()
          ? _value.icon
          // ignore: cast_nullable_to_non_nullable
          : icon as String?,
      theme: theme == const $CopyWithPlaceholder()
          ? _value.theme
          // ignore: cast_nullable_to_non_nullable
          : theme as String?,
      containerId: containerId == const $CopyWithPlaceholder()
          ? _value.containerId
          // ignore: cast_nullable_to_non_nullable
          : containerId as String?,
      orderIndex:
          orderIndex == const $CopyWithPlaceholder() || orderIndex == null
          ? _value.orderIndex
          // ignore: cast_nullable_to_non_nullable
          : orderIndex as int,
    );
  }
}

extension $SpaceDataCopyWith on SpaceData {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSpaceData.copyWith(...)` or `instanceOfSpaceData.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SpaceDataCWProxy get copyWith => _$SpaceDataCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpaceData _$SpaceDataFromJson(Map<String, dynamic> json) => SpaceData(
  uuid: json['uuid'] as String,
  name: json['name'] as String? ?? '',
  icon: json['icon'] as String?,
  theme: json['theme'] as String?,
  containerId: json['containerId'] as String?,
  orderIndex: (json['orderIndex'] as num).toInt(),
);

Map<String, dynamic> _$SpaceDataToJson(SpaceData instance) => <String, dynamic>{
  'uuid': instance.uuid,
  'name': instance.name,
  'icon': instance.icon,
  'theme': instance.theme,
  'containerId': instance.containerId,
  'orderIndex': instance.orderIndex,
};
