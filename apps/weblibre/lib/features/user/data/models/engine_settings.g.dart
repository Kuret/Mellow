// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'engine_settings.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CustomDohProviderCWProxy {
  CustomDohProvider url(String url);

  CustomDohProvider name(String? name);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `CustomDohProvider(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CustomDohProvider(...).copyWith(id: 12, name: "My name")
  /// ```
  CustomDohProvider call({String url, String? name});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCustomDohProvider.copyWith(...)` or call `instanceOfCustomDohProvider.copyWith.fieldName(value)` for a single field.
class _$CustomDohProviderCWProxyImpl implements _$CustomDohProviderCWProxy {
  const _$CustomDohProviderCWProxyImpl(this._value);

  final CustomDohProvider _value;

  @override
  CustomDohProvider url(String url) => call(url: url);

  @override
  CustomDohProvider name(String? name) => call(name: name);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `CustomDohProvider(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CustomDohProvider(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CustomDohProvider call({
    Object? url = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return CustomDohProvider(
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
    );
  }
}

extension $CustomDohProviderCopyWith on CustomDohProvider {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCustomDohProvider.copyWith(...)` or `instanceOfCustomDohProvider.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CustomDohProviderCWProxy get copyWith =>
      _$CustomDohProviderCWProxyImpl(this);
}

abstract class _$EngineSettingsCWProxy {
  EngineSettings javascriptEnabled(bool? javascriptEnabled);

  EngineSettings trackingProtectionPolicy(
    TrackingProtectionPolicy? trackingProtectionPolicy,
  );

  EngineSettings preferredColorScheme(ColorScheme? preferredColorScheme);

  EngineSettings userAgent(String? userAgent);

  EngineSettings enterpriseRootsEnabled(bool? enterpriseRootsEnabled);

  EngineSettings addonCollection(AddonCollection? addonCollection);

  EngineSettings ublockFilterListSettings(
    UBlockFilterListSettings ublockFilterListSettings,
  );

  EngineSettings dohSettingsMode(DohSettingsMode dohSettingsMode);

  EngineSettings dohProviderUrl(String dohProviderUrl);

  EngineSettings dohDefaultProviderUrl(String dohDefaultProviderUrl);

  EngineSettings dohExceptionsList(List<String> dohExceptionsList);

  EngineSettings customDohProviders(List<CustomDohProvider> customDohProviders);

  EngineSettings displayDensityOverride(double? displayDensityOverride);

  EngineSettings screenWidthOverride(int? screenWidthOverride);

  EngineSettings screenHeightOverride(int? screenHeightOverride);

  EngineSettings isolatedProcessEnabled(bool? isolatedProcessEnabled);

  EngineSettings appZygoteProcessEnabled(bool? appZygoteProcessEnabled);

  EngineSettings remoteDebuggingEnabled(bool? remoteDebuggingEnabled);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `EngineSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EngineSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  EngineSettings call({
    bool? javascriptEnabled,
    TrackingProtectionPolicy? trackingProtectionPolicy,
    ColorScheme? preferredColorScheme,
    String? userAgent,
    bool? enterpriseRootsEnabled,
    AddonCollection? addonCollection,
    UBlockFilterListSettings ublockFilterListSettings,
    DohSettingsMode dohSettingsMode,
    String dohProviderUrl,
    String dohDefaultProviderUrl,
    List<String> dohExceptionsList,
    List<CustomDohProvider> customDohProviders,
    double? displayDensityOverride,
    int? screenWidthOverride,
    int? screenHeightOverride,
    bool? isolatedProcessEnabled,
    bool? appZygoteProcessEnabled,
    bool? remoteDebuggingEnabled,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfEngineSettings.copyWith(...)` or call `instanceOfEngineSettings.copyWith.fieldName(value)` for a single field.
class _$EngineSettingsCWProxyImpl implements _$EngineSettingsCWProxy {
  const _$EngineSettingsCWProxyImpl(this._value);

  final EngineSettings _value;

  @override
  EngineSettings javascriptEnabled(bool? javascriptEnabled) =>
      call(javascriptEnabled: javascriptEnabled);

  @override
  EngineSettings trackingProtectionPolicy(
    TrackingProtectionPolicy? trackingProtectionPolicy,
  ) => call(trackingProtectionPolicy: trackingProtectionPolicy);

  @override
  EngineSettings preferredColorScheme(ColorScheme? preferredColorScheme) =>
      call(preferredColorScheme: preferredColorScheme);

  @override
  EngineSettings userAgent(String? userAgent) => call(userAgent: userAgent);

  @override
  EngineSettings enterpriseRootsEnabled(bool? enterpriseRootsEnabled) =>
      call(enterpriseRootsEnabled: enterpriseRootsEnabled);

  @override
  EngineSettings addonCollection(AddonCollection? addonCollection) =>
      call(addonCollection: addonCollection);

  @override
  EngineSettings ublockFilterListSettings(
    UBlockFilterListSettings ublockFilterListSettings,
  ) => call(ublockFilterListSettings: ublockFilterListSettings);

  @override
  EngineSettings dohSettingsMode(DohSettingsMode dohSettingsMode) =>
      call(dohSettingsMode: dohSettingsMode);

  @override
  EngineSettings dohProviderUrl(String dohProviderUrl) =>
      call(dohProviderUrl: dohProviderUrl);

  @override
  EngineSettings dohDefaultProviderUrl(String dohDefaultProviderUrl) =>
      call(dohDefaultProviderUrl: dohDefaultProviderUrl);

  @override
  EngineSettings dohExceptionsList(List<String> dohExceptionsList) =>
      call(dohExceptionsList: dohExceptionsList);

  @override
  EngineSettings customDohProviders(
    List<CustomDohProvider> customDohProviders,
  ) => call(customDohProviders: customDohProviders);

  @override
  EngineSettings displayDensityOverride(double? displayDensityOverride) =>
      call(displayDensityOverride: displayDensityOverride);

  @override
  EngineSettings screenWidthOverride(int? screenWidthOverride) =>
      call(screenWidthOverride: screenWidthOverride);

  @override
  EngineSettings screenHeightOverride(int? screenHeightOverride) =>
      call(screenHeightOverride: screenHeightOverride);

  @override
  EngineSettings isolatedProcessEnabled(bool? isolatedProcessEnabled) =>
      call(isolatedProcessEnabled: isolatedProcessEnabled);

  @override
  EngineSettings appZygoteProcessEnabled(bool? appZygoteProcessEnabled) =>
      call(appZygoteProcessEnabled: appZygoteProcessEnabled);

  @override
  EngineSettings remoteDebuggingEnabled(bool? remoteDebuggingEnabled) =>
      call(remoteDebuggingEnabled: remoteDebuggingEnabled);

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored. To update a single field use `EngineSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// EngineSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  EngineSettings call({
    Object? javascriptEnabled = const $CopyWithPlaceholder(),
    Object? trackingProtectionPolicy = const $CopyWithPlaceholder(),
    Object? preferredColorScheme = const $CopyWithPlaceholder(),
    Object? userAgent = const $CopyWithPlaceholder(),
    Object? enterpriseRootsEnabled = const $CopyWithPlaceholder(),
    Object? addonCollection = const $CopyWithPlaceholder(),
    Object? ublockFilterListSettings = const $CopyWithPlaceholder(),
    Object? dohSettingsMode = const $CopyWithPlaceholder(),
    Object? dohProviderUrl = const $CopyWithPlaceholder(),
    Object? dohDefaultProviderUrl = const $CopyWithPlaceholder(),
    Object? dohExceptionsList = const $CopyWithPlaceholder(),
    Object? customDohProviders = const $CopyWithPlaceholder(),
    Object? displayDensityOverride = const $CopyWithPlaceholder(),
    Object? screenWidthOverride = const $CopyWithPlaceholder(),
    Object? screenHeightOverride = const $CopyWithPlaceholder(),
    Object? isolatedProcessEnabled = const $CopyWithPlaceholder(),
    Object? appZygoteProcessEnabled = const $CopyWithPlaceholder(),
    Object? remoteDebuggingEnabled = const $CopyWithPlaceholder(),
  }) {
    return EngineSettings(
      javascriptEnabled: javascriptEnabled == const $CopyWithPlaceholder()
          ? _value.javascriptEnabled
          // ignore: cast_nullable_to_non_nullable
          : javascriptEnabled as bool?,
      trackingProtectionPolicy:
          trackingProtectionPolicy == const $CopyWithPlaceholder()
          ? _value.trackingProtectionPolicy
          // ignore: cast_nullable_to_non_nullable
          : trackingProtectionPolicy as TrackingProtectionPolicy?,
      preferredColorScheme: preferredColorScheme == const $CopyWithPlaceholder()
          ? _value.preferredColorScheme
          // ignore: cast_nullable_to_non_nullable
          : preferredColorScheme as ColorScheme?,
      userAgent: userAgent == const $CopyWithPlaceholder()
          ? _value.userAgent
          // ignore: cast_nullable_to_non_nullable
          : userAgent as String?,
      enterpriseRootsEnabled:
          enterpriseRootsEnabled == const $CopyWithPlaceholder()
          ? _value.enterpriseRootsEnabled
          // ignore: cast_nullable_to_non_nullable
          : enterpriseRootsEnabled as bool?,
      addonCollection: addonCollection == const $CopyWithPlaceholder()
          ? _value.addonCollection
          // ignore: cast_nullable_to_non_nullable
          : addonCollection as AddonCollection?,
      ublockFilterListSettings:
          ublockFilterListSettings == const $CopyWithPlaceholder() ||
              ublockFilterListSettings == null
          ? _value.ublockFilterListSettings
          // ignore: cast_nullable_to_non_nullable
          : ublockFilterListSettings as UBlockFilterListSettings,
      dohSettingsMode:
          dohSettingsMode == const $CopyWithPlaceholder() ||
              dohSettingsMode == null
          ? _value.dohSettingsMode
          // ignore: cast_nullable_to_non_nullable
          : dohSettingsMode as DohSettingsMode,
      dohProviderUrl:
          dohProviderUrl == const $CopyWithPlaceholder() ||
              dohProviderUrl == null
          ? _value.dohProviderUrl
          // ignore: cast_nullable_to_non_nullable
          : dohProviderUrl as String,
      dohDefaultProviderUrl:
          dohDefaultProviderUrl == const $CopyWithPlaceholder() ||
              dohDefaultProviderUrl == null
          ? _value.dohDefaultProviderUrl
          // ignore: cast_nullable_to_non_nullable
          : dohDefaultProviderUrl as String,
      dohExceptionsList:
          dohExceptionsList == const $CopyWithPlaceholder() ||
              dohExceptionsList == null
          ? _value.dohExceptionsList
          // ignore: cast_nullable_to_non_nullable
          : dohExceptionsList as List<String>,
      customDohProviders:
          customDohProviders == const $CopyWithPlaceholder() ||
              customDohProviders == null
          ? _value.customDohProviders
          // ignore: cast_nullable_to_non_nullable
          : customDohProviders as List<CustomDohProvider>,
      displayDensityOverride:
          displayDensityOverride == const $CopyWithPlaceholder()
          ? _value.displayDensityOverride
          // ignore: cast_nullable_to_non_nullable
          : displayDensityOverride as double?,
      screenWidthOverride: screenWidthOverride == const $CopyWithPlaceholder()
          ? _value.screenWidthOverride
          // ignore: cast_nullable_to_non_nullable
          : screenWidthOverride as int?,
      screenHeightOverride: screenHeightOverride == const $CopyWithPlaceholder()
          ? _value.screenHeightOverride
          // ignore: cast_nullable_to_non_nullable
          : screenHeightOverride as int?,
      isolatedProcessEnabled:
          isolatedProcessEnabled == const $CopyWithPlaceholder()
          ? _value.isolatedProcessEnabled
          // ignore: cast_nullable_to_non_nullable
          : isolatedProcessEnabled as bool?,
      appZygoteProcessEnabled:
          appZygoteProcessEnabled == const $CopyWithPlaceholder()
          ? _value.appZygoteProcessEnabled
          // ignore: cast_nullable_to_non_nullable
          : appZygoteProcessEnabled as bool?,
      remoteDebuggingEnabled:
          remoteDebuggingEnabled == const $CopyWithPlaceholder()
          ? _value.remoteDebuggingEnabled
          // ignore: cast_nullable_to_non_nullable
          : remoteDebuggingEnabled as bool?,
    );
  }
}

extension $EngineSettingsCopyWith on EngineSettings {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfEngineSettings.copyWith(...)` or `instanceOfEngineSettings.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EngineSettingsCWProxy get copyWith => _$EngineSettingsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomDohProvider _$CustomDohProviderFromJson(Map<String, dynamic> json) =>
    CustomDohProvider(
      url: json['url'] as String,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$CustomDohProviderToJson(CustomDohProvider instance) =>
    <String, dynamic>{'url': instance.url, 'name': ?instance.name};

EngineSettings _$EngineSettingsFromJson(Map<String, dynamic> json) =>
    EngineSettings.withDefaults(
        javascriptEnabled: json['javascriptEnabled'] as bool?,
        trackingProtectionPolicy: $enumDecodeNullable(
          _$TrackingProtectionPolicyEnumMap,
          json['trackingProtectionPolicy'],
        ),
        preferredColorScheme: $enumDecodeNullable(
          _$ColorSchemeEnumMap,
          json['preferredColorScheme'],
        ),
        userAgent: json['userAgent'] as String?,
        enterpriseRootsEnabled: json['enterpriseRootsEnabled'] as bool?,
        addonCollection: EngineSettings._addonCollectionFromJson(
          json['addonCollection'] as String?,
        ),
        ublockFilterListSettings:
            EngineSettings._ublockFilterListSettingsFromJson(
              json['ublockFilterListSettings'] as String?,
            ),
        dohSettingsMode: $enumDecodeNullable(
          _$DohSettingsModeEnumMap,
          json['dohSettingsMode'],
        ),
        dohProviderUrl: json['dohProviderUrl'] as String?,
        dohDefaultProviderUrl: json['dohDefaultProviderUrl'] as String?,
        dohExceptionsList: (json['dohExceptionsList'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        customDohProviders: (json['customDohProviders'] as List<dynamic>?)
            ?.map((e) => CustomDohProvider.fromJson(e as Map<String, dynamic>))
            .toList(),
        displayDensityOverride: (json['displayDensityOverride'] as num?)
            ?.toDouble(),
        screenWidthOverride: (json['screenWidthOverride'] as num?)?.toInt(),
        screenHeightOverride: (json['screenHeightOverride'] as num?)?.toInt(),
        isolatedProcessEnabled: json['isolatedProcessEnabled'] as bool?,
        appZygoteProcessEnabled: json['appZygoteProcessEnabled'] as bool?,
        remoteDebuggingEnabled: json['remoteDebuggingEnabled'] as bool?,
      )
      ..cookieBannerHandlingMode = $enumDecodeNullable(
        _$CookieBannerHandlingModeEnumMap,
        json['cookieBannerHandlingMode'],
      )
      ..cookieBannerHandlingModePrivateBrowsing = $enumDecodeNullable(
        _$CookieBannerHandlingModeEnumMap,
        json['cookieBannerHandlingModePrivateBrowsing'],
      )
      ..cookieBannerHandlingGlobalRules =
          json['cookieBannerHandlingGlobalRules'] as bool?
      ..cookieBannerHandlingGlobalRulesSubFrames =
          json['cookieBannerHandlingGlobalRulesSubFrames'] as bool?;

Map<String, dynamic> _$EngineSettingsToJson(
  EngineSettings instance,
) => <String, dynamic>{
  'cookieBannerHandlingMode':
      _$CookieBannerHandlingModeEnumMap[instance.cookieBannerHandlingMode],
  'cookieBannerHandlingModePrivateBrowsing':
      _$CookieBannerHandlingModeEnumMap[instance
          .cookieBannerHandlingModePrivateBrowsing],
  'cookieBannerHandlingGlobalRules': instance.cookieBannerHandlingGlobalRules,
  'cookieBannerHandlingGlobalRulesSubFrames':
      instance.cookieBannerHandlingGlobalRulesSubFrames,
  'userAgent': instance.userAgent,
  'displayDensityOverride': instance.displayDensityOverride,
  'screenWidthOverride': instance.screenWidthOverride,
  'screenHeightOverride': instance.screenHeightOverride,
  'javascriptEnabled': instance.javascriptEnabled,
  'trackingProtectionPolicy':
      _$TrackingProtectionPolicyEnumMap[instance.trackingProtectionPolicy]!,
  'preferredColorScheme': _$ColorSchemeEnumMap[instance.preferredColorScheme]!,
  'enterpriseRootsEnabled': instance.enterpriseRootsEnabled,
  'isolatedProcessEnabled': instance.isolatedProcessEnabled,
  'appZygoteProcessEnabled': instance.appZygoteProcessEnabled,
  'remoteDebuggingEnabled': instance.remoteDebuggingEnabled,
  'addonCollection': EngineSettings._addonCollectionToJson(
    instance.addonCollection,
  ),
  'ublockFilterListSettings': EngineSettings._ublockFilterListSettingsToJson(
    instance.ublockFilterListSettings,
  ),
  'dohSettingsMode': _$DohSettingsModeEnumMap[instance.dohSettingsMode]!,
  'dohProviderUrl': instance.dohProviderUrl,
  'dohDefaultProviderUrl': instance.dohDefaultProviderUrl,
  'dohExceptionsList': instance.dohExceptionsList,
  'customDohProviders': instance.customDohProviders
      .map((e) => e.toJson())
      .toList(),
};

const _$TrackingProtectionPolicyEnumMap = {
  TrackingProtectionPolicy.none: 'none',
  TrackingProtectionPolicy.recommended: 'recommended',
  TrackingProtectionPolicy.strict: 'strict',
  TrackingProtectionPolicy.custom: 'custom',
};

const _$ColorSchemeEnumMap = {
  ColorScheme.system: 'system',
  ColorScheme.light: 'light',
  ColorScheme.dark: 'dark',
};

const _$DohSettingsModeEnumMap = {
  DohSettingsMode.geckoDefault: 'geckoDefault',
  DohSettingsMode.increased: 'increased',
  DohSettingsMode.max: 'max',
  DohSettingsMode.off: 'off',
};

const _$CookieBannerHandlingModeEnumMap = {
  CookieBannerHandlingMode.disabled: 'disabled',
  CookieBannerHandlingMode.rejectAll: 'rejectAll',
  CookieBannerHandlingMode.rejectOrAcceptAll: 'rejectOrAcceptAll',
};
