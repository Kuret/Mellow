// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zen_settings.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CustomSearchEngineCWProxy {
  CustomSearchEngine id(String id);

  CustomSearchEngine name(String name);

  CustomSearchEngine urlTemplate(String urlTemplate);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `CustomSearchEngine(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CustomSearchEngine(...).copyWith(id: 12, name: "My name")
  /// ```
  CustomSearchEngine call({String id, String name, String urlTemplate});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCustomSearchEngine.copyWith(...)` or call `instanceOfCustomSearchEngine.copyWith.fieldName(value)` for a single field.
class _$CustomSearchEngineCWProxyImpl implements _$CustomSearchEngineCWProxy {
  const _$CustomSearchEngineCWProxyImpl(this._value);

  final CustomSearchEngine _value;

  @override
  CustomSearchEngine id(String id) => call(id: id);

  @override
  CustomSearchEngine name(String name) => call(name: name);

  @override
  CustomSearchEngine urlTemplate(String urlTemplate) =>
      call(urlTemplate: urlTemplate);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `CustomSearchEngine(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CustomSearchEngine(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CustomSearchEngine call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? urlTemplate = const $CopyWithPlaceholder(),
  }) {
    return CustomSearchEngine(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      urlTemplate:
          urlTemplate == const $CopyWithPlaceholder() || urlTemplate == null
          ? _value.urlTemplate
          // ignore: cast_nullable_to_non_nullable
          : urlTemplate as String,
    );
  }
}

extension $CustomSearchEngineCopyWith on CustomSearchEngine {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCustomSearchEngine.copyWith(...)` or `instanceOfCustomSearchEngine.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CustomSearchEngineCWProxy get copyWith =>
      _$CustomSearchEngineCWProxyImpl(this);
}

abstract class _$ZenSettingsCWProxy {
  ZenSettings spacesSyncEnabled(bool spacesSyncEnabled);

  ZenSettings spacesSyncWritesEnabled(bool spacesSyncWritesEnabled);

  ZenSettings spacesSyncLastSyncId(String? spacesSyncLastSyncId);

  ZenSettings spacesSyncLastModified(double? spacesSyncLastModified);

  ZenSettings spacesSyncBaselineDone(bool spacesSyncBaselineDone);

  ZenSettings spacesSyncApplierVersion(int spacesSyncApplierVersion);

  ZenSettings spacesSyncMaxTombstoneFraction(
    double spacesSyncMaxTombstoneFraction,
  );

  ZenSettings spacesSyncMaxTombstoneCount(int spacesSyncMaxTombstoneCount);

  ZenSettings railSide(RailSide railSide);

  ZenSettings spaceIndicatorSide(SpaceIndicatorSide spaceIndicatorSide);

  ZenSettings railWidth(double railWidth);

  ZenSettings compactRailSide(CompactRailSide? compactRailSide);

  ZenSettings swipeToMoveRail(bool swipeToMoveRail);

  ZenSettings showToolbarButtons(bool showToolbarButtons);

  ZenSettings maxLiveTabs(int maxLiveTabs);

  ZenSettings separateEssentials(bool separateEssentials);

  ZenSettings customSearchProviders(
    List<CustomSearchEngine> customSearchProviders,
  );

  ZenSettings profileDefaultsRevision(int profileDefaultsRevision);

  ZenSettings accentColor(int? accentColor);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `ZenSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ZenSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  ZenSettings call({
    bool spacesSyncEnabled,
    bool spacesSyncWritesEnabled,
    String? spacesSyncLastSyncId,
    double? spacesSyncLastModified,
    bool spacesSyncBaselineDone,
    int spacesSyncApplierVersion,
    double spacesSyncMaxTombstoneFraction,
    int spacesSyncMaxTombstoneCount,
    RailSide railSide,
    SpaceIndicatorSide spaceIndicatorSide,
    double railWidth,
    CompactRailSide? compactRailSide,
    bool swipeToMoveRail,
    bool showToolbarButtons,
    int maxLiveTabs,
    bool separateEssentials,
    List<CustomSearchEngine> customSearchProviders,
    int profileDefaultsRevision,
    int? accentColor,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfZenSettings.copyWith(...)` or call `instanceOfZenSettings.copyWith.fieldName(value)` for a single field.
class _$ZenSettingsCWProxyImpl implements _$ZenSettingsCWProxy {
  const _$ZenSettingsCWProxyImpl(this._value);

  final ZenSettings _value;

  @override
  ZenSettings spacesSyncEnabled(bool spacesSyncEnabled) =>
      call(spacesSyncEnabled: spacesSyncEnabled);

  @override
  ZenSettings spacesSyncWritesEnabled(bool spacesSyncWritesEnabled) =>
      call(spacesSyncWritesEnabled: spacesSyncWritesEnabled);

  @override
  ZenSettings spacesSyncLastSyncId(String? spacesSyncLastSyncId) =>
      call(spacesSyncLastSyncId: spacesSyncLastSyncId);

  @override
  ZenSettings spacesSyncLastModified(double? spacesSyncLastModified) =>
      call(spacesSyncLastModified: spacesSyncLastModified);

  @override
  ZenSettings spacesSyncBaselineDone(bool spacesSyncBaselineDone) =>
      call(spacesSyncBaselineDone: spacesSyncBaselineDone);

  @override
  ZenSettings spacesSyncApplierVersion(int spacesSyncApplierVersion) =>
      call(spacesSyncApplierVersion: spacesSyncApplierVersion);

  @override
  ZenSettings spacesSyncMaxTombstoneFraction(
    double spacesSyncMaxTombstoneFraction,
  ) => call(spacesSyncMaxTombstoneFraction: spacesSyncMaxTombstoneFraction);

  @override
  ZenSettings spacesSyncMaxTombstoneCount(int spacesSyncMaxTombstoneCount) =>
      call(spacesSyncMaxTombstoneCount: spacesSyncMaxTombstoneCount);

  @override
  ZenSettings railSide(RailSide railSide) => call(railSide: railSide);

  @override
  ZenSettings spaceIndicatorSide(SpaceIndicatorSide spaceIndicatorSide) =>
      call(spaceIndicatorSide: spaceIndicatorSide);

  @override
  ZenSettings railWidth(double railWidth) => call(railWidth: railWidth);

  @override
  ZenSettings compactRailSide(CompactRailSide? compactRailSide) =>
      call(compactRailSide: compactRailSide);

  @override
  ZenSettings swipeToMoveRail(bool swipeToMoveRail) =>
      call(swipeToMoveRail: swipeToMoveRail);

  @override
  ZenSettings showToolbarButtons(bool showToolbarButtons) =>
      call(showToolbarButtons: showToolbarButtons);

  @override
  ZenSettings maxLiveTabs(int maxLiveTabs) => call(maxLiveTabs: maxLiveTabs);

  @override
  ZenSettings separateEssentials(bool separateEssentials) =>
      call(separateEssentials: separateEssentials);

  @override
  ZenSettings customSearchProviders(
    List<CustomSearchEngine> customSearchProviders,
  ) => call(customSearchProviders: customSearchProviders);

  @override
  ZenSettings profileDefaultsRevision(int profileDefaultsRevision) =>
      call(profileDefaultsRevision: profileDefaultsRevision);

  @override
  ZenSettings accentColor(int? accentColor) => call(accentColor: accentColor);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `ZenSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ZenSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ZenSettings call({
    Object? spacesSyncEnabled = const $CopyWithPlaceholder(),
    Object? spacesSyncWritesEnabled = const $CopyWithPlaceholder(),
    Object? spacesSyncLastSyncId = const $CopyWithPlaceholder(),
    Object? spacesSyncLastModified = const $CopyWithPlaceholder(),
    Object? spacesSyncBaselineDone = const $CopyWithPlaceholder(),
    Object? spacesSyncApplierVersion = const $CopyWithPlaceholder(),
    Object? spacesSyncMaxTombstoneFraction = const $CopyWithPlaceholder(),
    Object? spacesSyncMaxTombstoneCount = const $CopyWithPlaceholder(),
    Object? railSide = const $CopyWithPlaceholder(),
    Object? spaceIndicatorSide = const $CopyWithPlaceholder(),
    Object? railWidth = const $CopyWithPlaceholder(),
    Object? compactRailSide = const $CopyWithPlaceholder(),
    Object? swipeToMoveRail = const $CopyWithPlaceholder(),
    Object? showToolbarButtons = const $CopyWithPlaceholder(),
    Object? maxLiveTabs = const $CopyWithPlaceholder(),
    Object? separateEssentials = const $CopyWithPlaceholder(),
    Object? customSearchProviders = const $CopyWithPlaceholder(),
    Object? profileDefaultsRevision = const $CopyWithPlaceholder(),
    Object? accentColor = const $CopyWithPlaceholder(),
  }) {
    return ZenSettings(
      spacesSyncEnabled:
          spacesSyncEnabled == const $CopyWithPlaceholder() ||
              spacesSyncEnabled == null
          ? _value.spacesSyncEnabled
          // ignore: cast_nullable_to_non_nullable
          : spacesSyncEnabled as bool,
      spacesSyncWritesEnabled:
          spacesSyncWritesEnabled == const $CopyWithPlaceholder() ||
              spacesSyncWritesEnabled == null
          ? _value.spacesSyncWritesEnabled
          // ignore: cast_nullable_to_non_nullable
          : spacesSyncWritesEnabled as bool,
      spacesSyncLastSyncId: spacesSyncLastSyncId == const $CopyWithPlaceholder()
          ? _value.spacesSyncLastSyncId
          // ignore: cast_nullable_to_non_nullable
          : spacesSyncLastSyncId as String?,
      spacesSyncLastModified:
          spacesSyncLastModified == const $CopyWithPlaceholder()
          ? _value.spacesSyncLastModified
          // ignore: cast_nullable_to_non_nullable
          : spacesSyncLastModified as double?,
      spacesSyncBaselineDone:
          spacesSyncBaselineDone == const $CopyWithPlaceholder() ||
              spacesSyncBaselineDone == null
          ? _value.spacesSyncBaselineDone
          // ignore: cast_nullable_to_non_nullable
          : spacesSyncBaselineDone as bool,
      spacesSyncApplierVersion:
          spacesSyncApplierVersion == const $CopyWithPlaceholder() ||
              spacesSyncApplierVersion == null
          ? _value.spacesSyncApplierVersion
          // ignore: cast_nullable_to_non_nullable
          : spacesSyncApplierVersion as int,
      spacesSyncMaxTombstoneFraction:
          spacesSyncMaxTombstoneFraction == const $CopyWithPlaceholder() ||
              spacesSyncMaxTombstoneFraction == null
          ? _value.spacesSyncMaxTombstoneFraction
          // ignore: cast_nullable_to_non_nullable
          : spacesSyncMaxTombstoneFraction as double,
      spacesSyncMaxTombstoneCount:
          spacesSyncMaxTombstoneCount == const $CopyWithPlaceholder() ||
              spacesSyncMaxTombstoneCount == null
          ? _value.spacesSyncMaxTombstoneCount
          // ignore: cast_nullable_to_non_nullable
          : spacesSyncMaxTombstoneCount as int,
      railSide: railSide == const $CopyWithPlaceholder() || railSide == null
          ? _value.railSide
          // ignore: cast_nullable_to_non_nullable
          : railSide as RailSide,
      spaceIndicatorSide:
          spaceIndicatorSide == const $CopyWithPlaceholder() ||
              spaceIndicatorSide == null
          ? _value.spaceIndicatorSide
          // ignore: cast_nullable_to_non_nullable
          : spaceIndicatorSide as SpaceIndicatorSide,
      railWidth: railWidth == const $CopyWithPlaceholder() || railWidth == null
          ? _value.railWidth
          // ignore: cast_nullable_to_non_nullable
          : railWidth as double,
      compactRailSide: compactRailSide == const $CopyWithPlaceholder()
          ? _value.compactRailSide
          // ignore: cast_nullable_to_non_nullable
          : compactRailSide as CompactRailSide?,
      swipeToMoveRail:
          swipeToMoveRail == const $CopyWithPlaceholder() ||
              swipeToMoveRail == null
          ? _value.swipeToMoveRail
          // ignore: cast_nullable_to_non_nullable
          : swipeToMoveRail as bool,
      showToolbarButtons:
          showToolbarButtons == const $CopyWithPlaceholder() ||
              showToolbarButtons == null
          ? _value.showToolbarButtons
          // ignore: cast_nullable_to_non_nullable
          : showToolbarButtons as bool,
      maxLiveTabs:
          maxLiveTabs == const $CopyWithPlaceholder() || maxLiveTabs == null
          ? _value.maxLiveTabs
          // ignore: cast_nullable_to_non_nullable
          : maxLiveTabs as int,
      separateEssentials:
          separateEssentials == const $CopyWithPlaceholder() ||
              separateEssentials == null
          ? _value.separateEssentials
          // ignore: cast_nullable_to_non_nullable
          : separateEssentials as bool,
      customSearchProviders:
          customSearchProviders == const $CopyWithPlaceholder() ||
              customSearchProviders == null
          ? _value.customSearchProviders
          // ignore: cast_nullable_to_non_nullable
          : customSearchProviders as List<CustomSearchEngine>,
      profileDefaultsRevision:
          profileDefaultsRevision == const $CopyWithPlaceholder() ||
              profileDefaultsRevision == null
          ? _value.profileDefaultsRevision
          // ignore: cast_nullable_to_non_nullable
          : profileDefaultsRevision as int,
      accentColor: accentColor == const $CopyWithPlaceholder()
          ? _value.accentColor
          // ignore: cast_nullable_to_non_nullable
          : accentColor as int?,
    );
  }
}

extension $ZenSettingsCopyWith on ZenSettings {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfZenSettings.copyWith(...)` or `instanceOfZenSettings.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ZenSettingsCWProxy get copyWith => _$ZenSettingsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomSearchEngine _$CustomSearchEngineFromJson(Map<String, dynamic> json) =>
    CustomSearchEngine(
      id: json['id'] as String,
      name: json['name'] as String,
      urlTemplate: json['urlTemplate'] as String,
    );

Map<String, dynamic> _$CustomSearchEngineToJson(CustomSearchEngine instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'urlTemplate': instance.urlTemplate,
    };

ZenSettings _$ZenSettingsFromJson(
  Map<String, dynamic> json,
) => ZenSettings.withDefaults(
  spacesSyncEnabled: json['spacesSyncEnabled'] as bool?,
  spacesSyncWritesEnabled: json['spacesSyncWritesEnabled'] as bool?,
  spacesSyncLastSyncId: json['spacesSyncLastSyncId'] as String?,
  spacesSyncLastModified: (json['spacesSyncLastModified'] as num?)?.toDouble(),
  spacesSyncBaselineDone: json['spacesSyncBaselineDone'] as bool?,
  spacesSyncApplierVersion: (json['spacesSyncApplierVersion'] as num?)?.toInt(),
  spacesSyncMaxTombstoneFraction:
      (json['spacesSyncMaxTombstoneFraction'] as num?)?.toDouble(),
  spacesSyncMaxTombstoneCount: (json['spacesSyncMaxTombstoneCount'] as num?)
      ?.toInt(),
  railSide: $enumDecodeNullable(_$RailSideEnumMap, json['railSide']),
  spaceIndicatorSide: $enumDecodeNullable(
    _$SpaceIndicatorSideEnumMap,
    json['spaceIndicatorSide'],
  ),
  railWidth: (json['railWidth'] as num?)?.toDouble(),
  compactRailSide: $enumDecodeNullable(
    _$CompactRailSideEnumMap,
    json['compactRailSide'],
  ),
  swipeToMoveRail: json['swipeToMoveRail'] as bool?,
  showToolbarButtons: json['showRailToolbar'] as bool?,
  maxLiveTabs: (json['maxLiveTabs'] as num?)?.toInt(),
  separateEssentials: json['separateEssentials'] as bool?,
  customSearchProviders: (json['customSearchProviders'] as List<dynamic>?)
      ?.map((e) => CustomSearchEngine.fromJson(e as Map<String, dynamic>))
      .toList(),
  profileDefaultsRevision: (json['profileDefaultsRevision'] as num?)?.toInt(),
  accentColor: (json['accentColor'] as num?)?.toInt(),
);

Map<String, dynamic> _$ZenSettingsToJson(ZenSettings instance) =>
    <String, dynamic>{
      'spacesSyncEnabled': instance.spacesSyncEnabled,
      'spacesSyncWritesEnabled': instance.spacesSyncWritesEnabled,
      'spacesSyncLastSyncId': instance.spacesSyncLastSyncId,
      'spacesSyncLastModified': instance.spacesSyncLastModified,
      'spacesSyncBaselineDone': instance.spacesSyncBaselineDone,
      'spacesSyncApplierVersion': instance.spacesSyncApplierVersion,
      'spacesSyncMaxTombstoneFraction': instance.spacesSyncMaxTombstoneFraction,
      'spacesSyncMaxTombstoneCount': instance.spacesSyncMaxTombstoneCount,
      'railSide': _$RailSideEnumMap[instance.railSide]!,
      'spaceIndicatorSide':
          _$SpaceIndicatorSideEnumMap[instance.spaceIndicatorSide]!,
      'railWidth': instance.railWidth,
      'compactRailSide': _$CompactRailSideEnumMap[instance.compactRailSide],
      'swipeToMoveRail': instance.swipeToMoveRail,
      'showRailToolbar': instance.showToolbarButtons,
      'maxLiveTabs': instance.maxLiveTabs,
      'separateEssentials': instance.separateEssentials,
      'customSearchProviders': instance.customSearchProviders
          .map((e) => e.toJson())
          .toList(),
      'profileDefaultsRevision': instance.profileDefaultsRevision,
      'accentColor': instance.accentColor,
    };

const _$RailSideEnumMap = {RailSide.left: 'left', RailSide.right: 'right'};

const _$SpaceIndicatorSideEnumMap = {
  SpaceIndicatorSide.left: 'left',
  SpaceIndicatorSide.right: 'right',
};

const _$CompactRailSideEnumMap = {
  CompactRailSide.left: 'left',
  CompactRailSide.right: 'right',
  CompactRailSide.either: 'either',
};
