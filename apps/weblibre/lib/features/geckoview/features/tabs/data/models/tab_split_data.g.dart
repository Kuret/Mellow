// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tab_split_data.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TabSplitDataCWProxy {
  TabSplitData id(String id);

  TabSplitData gridType(String gridType);

  TabSplitData isPinned(bool isPinned);

  TabSplitData spaceUuid(String? spaceUuid);

  TabSplitData folderId(String? folderId);

  TabSplitData orderKey(String orderKey);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `TabSplitData(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TabSplitData(...).copyWith(id: 12, name: "My name")
  /// ```
  TabSplitData call({
    String id,
    String gridType,
    bool isPinned,
    String? spaceUuid,
    String? folderId,
    String orderKey,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTabSplitData.copyWith(...)` or call `instanceOfTabSplitData.copyWith.fieldName(value)` for a single field.
class _$TabSplitDataCWProxyImpl implements _$TabSplitDataCWProxy {
  const _$TabSplitDataCWProxyImpl(this._value);

  final TabSplitData _value;

  @override
  TabSplitData id(String id) => call(id: id);

  @override
  TabSplitData gridType(String gridType) => call(gridType: gridType);

  @override
  TabSplitData isPinned(bool isPinned) => call(isPinned: isPinned);

  @override
  TabSplitData spaceUuid(String? spaceUuid) => call(spaceUuid: spaceUuid);

  @override
  TabSplitData folderId(String? folderId) => call(folderId: folderId);

  @override
  TabSplitData orderKey(String orderKey) => call(orderKey: orderKey);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `TabSplitData(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TabSplitData(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TabSplitData call({
    Object? id = const $CopyWithPlaceholder(),
    Object? gridType = const $CopyWithPlaceholder(),
    Object? isPinned = const $CopyWithPlaceholder(),
    Object? spaceUuid = const $CopyWithPlaceholder(),
    Object? folderId = const $CopyWithPlaceholder(),
    Object? orderKey = const $CopyWithPlaceholder(),
  }) {
    return TabSplitData(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      gridType: gridType == const $CopyWithPlaceholder() || gridType == null
          ? _value.gridType
          // ignore: cast_nullable_to_non_nullable
          : gridType as String,
      isPinned: isPinned == const $CopyWithPlaceholder() || isPinned == null
          ? _value.isPinned
          // ignore: cast_nullable_to_non_nullable
          : isPinned as bool,
      spaceUuid: spaceUuid == const $CopyWithPlaceholder()
          ? _value.spaceUuid
          // ignore: cast_nullable_to_non_nullable
          : spaceUuid as String?,
      folderId: folderId == const $CopyWithPlaceholder()
          ? _value.folderId
          // ignore: cast_nullable_to_non_nullable
          : folderId as String?,
      orderKey: orderKey == const $CopyWithPlaceholder() || orderKey == null
          ? _value.orderKey
          // ignore: cast_nullable_to_non_nullable
          : orderKey as String,
    );
  }
}

extension $TabSplitDataCopyWith on TabSplitData {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTabSplitData.copyWith(...)` or `instanceOfTabSplitData.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TabSplitDataCWProxy get copyWith => _$TabSplitDataCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TabSplitData _$TabSplitDataFromJson(Map<String, dynamic> json) => TabSplitData(
  id: json['id'] as String,
  gridType: json['gridType'] as String? ?? 'grid',
  isPinned: json['isPinned'] as bool? ?? false,
  spaceUuid: json['spaceUuid'] as String?,
  folderId: json['folderId'] as String?,
  orderKey: json['orderKey'] as String,
);

Map<String, dynamic> _$TabSplitDataToJson(TabSplitData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'gridType': instance.gridType,
      'isPinned': instance.isPinned,
      'spaceUuid': instance.spaceUuid,
      'folderId': instance.folderId,
      'orderKey': instance.orderKey,
    };
