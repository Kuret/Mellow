// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'container_local_data.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ContainerLocalDataCWProxy {
  ContainerLocalData containerId(String containerId);

  ContainerLocalData excludeFromIndex(bool excludeFromIndex);

  ContainerLocalData excludeFromHistory(bool excludeFromHistory);

  ContainerLocalData clearDataOnExit(bool clearDataOnExit);

  ContainerLocalData wallpaper(String? wallpaper);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `ContainerLocalData(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ContainerLocalData(...).copyWith(id: 12, name: "My name")
  /// ```
  ContainerLocalData call({
    String containerId,
    bool excludeFromIndex,
    bool excludeFromHistory,
    bool clearDataOnExit,
    String? wallpaper,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfContainerLocalData.copyWith(...)` or call `instanceOfContainerLocalData.copyWith.fieldName(value)` for a single field.
class _$ContainerLocalDataCWProxyImpl implements _$ContainerLocalDataCWProxy {
  const _$ContainerLocalDataCWProxyImpl(this._value);

  final ContainerLocalData _value;

  @override
  ContainerLocalData containerId(String containerId) =>
      call(containerId: containerId);

  @override
  ContainerLocalData excludeFromIndex(bool excludeFromIndex) =>
      call(excludeFromIndex: excludeFromIndex);

  @override
  ContainerLocalData excludeFromHistory(bool excludeFromHistory) =>
      call(excludeFromHistory: excludeFromHistory);

  @override
  ContainerLocalData clearDataOnExit(bool clearDataOnExit) =>
      call(clearDataOnExit: clearDataOnExit);

  @override
  ContainerLocalData wallpaper(String? wallpaper) => call(wallpaper: wallpaper);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `ContainerLocalData(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ContainerLocalData(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ContainerLocalData call({
    Object? containerId = const $CopyWithPlaceholder(),
    Object? excludeFromIndex = const $CopyWithPlaceholder(),
    Object? excludeFromHistory = const $CopyWithPlaceholder(),
    Object? clearDataOnExit = const $CopyWithPlaceholder(),
    Object? wallpaper = const $CopyWithPlaceholder(),
  }) {
    return ContainerLocalData(
      containerId:
          containerId == const $CopyWithPlaceholder() || containerId == null
          ? _value.containerId
          // ignore: cast_nullable_to_non_nullable
          : containerId as String,
      excludeFromIndex:
          excludeFromIndex == const $CopyWithPlaceholder() ||
              excludeFromIndex == null
          ? _value.excludeFromIndex
          // ignore: cast_nullable_to_non_nullable
          : excludeFromIndex as bool,
      excludeFromHistory:
          excludeFromHistory == const $CopyWithPlaceholder() ||
              excludeFromHistory == null
          ? _value.excludeFromHistory
          // ignore: cast_nullable_to_non_nullable
          : excludeFromHistory as bool,
      clearDataOnExit:
          clearDataOnExit == const $CopyWithPlaceholder() ||
              clearDataOnExit == null
          ? _value.clearDataOnExit
          // ignore: cast_nullable_to_non_nullable
          : clearDataOnExit as bool,
      wallpaper: wallpaper == const $CopyWithPlaceholder()
          ? _value.wallpaper
          // ignore: cast_nullable_to_non_nullable
          : wallpaper as String?,
    );
  }
}

extension $ContainerLocalDataCopyWith on ContainerLocalData {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfContainerLocalData.copyWith(...)` or `instanceOfContainerLocalData.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ContainerLocalDataCWProxy get copyWith =>
      _$ContainerLocalDataCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContainerLocalData _$ContainerLocalDataFromJson(Map<String, dynamic> json) =>
    ContainerLocalData(
      containerId: json['containerId'] as String,
      excludeFromIndex: json['excludeFromIndex'] as bool? ?? false,
      excludeFromHistory: json['excludeFromHistory'] as bool? ?? false,
      clearDataOnExit: json['clearDataOnExit'] as bool? ?? false,
      wallpaper: json['wallpaper'] as String?,
    );

Map<String, dynamic> _$ContainerLocalDataToJson(ContainerLocalData instance) =>
    <String, dynamic>{
      'containerId': instance.containerId,
      'excludeFromIndex': instance.excludeFromIndex,
      'excludeFromHistory': instance.excludeFromHistory,
      'clearDataOnExit': instance.clearDataOnExit,
      'wallpaper': instance.wallpaper,
    };
