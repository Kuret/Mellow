/*
 * Copyright (c) 2024-2026 Fabian Freund.
 *
 * This file is part of WebLibre
 * (see https://weblibre.eu).
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import 'dart:convert';

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:fast_equatable/fast_equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mozilla_components/flutter_mozilla_components.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mellow/features/user/data/models/ublock_filter_list_settings.dart';
import 'package:mellow/features/user/domain/entities/fingerprint_overrides.dart';
import 'package:nullability/nullability.dart';

part 'engine_settings.g.dart';

enum BuiltInDohProviders {
  quad9('Quad9', 'https://dns.quad9.net/dns-query'),
  mullvad('Mullvad', 'https://dns.mullvad.net/dns-query'),
  adguard('AdGuard', 'https://dns.adguard-dns.com/dns-query'),
  ffmuc('Freifunk München', 'https://doh.ffmuc.net/dns-query');

  final String name;
  final String url;

  static bool isBuiltin(String url) =>
      BuiltInDohProviders.values.any((provider) => provider.url == url);

  const BuiltInDohProviders(this.name, this.url);
}

const kMaxCustomDohProviders = 16;

/// A user-added DoH resolver. Rendered next to [BuiltInDohProviders] so that
/// selecting one is a plain radio tap instead of a free-text field that has to
/// be committed through the keyboard.
@CopyWith()
@JsonSerializable(includeIfNull: true)
class CustomDohProvider with FastEquatable {
  final String url;

  @JsonKey(includeIfNull: false)
  final String? name;

  CustomDohProvider({required this.url, this.name});

  /// Falls back to the host so an unnamed resolver still reads as a label.
  String get displayName {
    final trimmed = name?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }

    final host = Uri.tryParse(url)?.host;

    return (host != null && host.isNotEmpty) ? host : url;
  }

  factory CustomDohProvider.fromJson(Map<String, dynamic> json) =>
      _$CustomDohProviderFromJson(json);

  Map<String, dynamic> toJson() => _$CustomDohProviderToJson(this);

  /// Adopts a resolver that only exists as the selected [dohProviderUrl] into
  /// the saved list. Before saved resolvers existed, a custom resolver lived
  /// nowhere else — without this it would disappear the moment the user picked
  /// a built-in provider instead.
  ///
  /// Runs on every deserialization, so the adopted entry is part of the model
  /// before anything can read it, and reaches the database with the next
  /// settings write. Covered end to end by `engine_settings_doh_test.dart`.
  static List<CustomDohProvider> adoptSelected(
    List<CustomDohProvider> providers,
    String dohProviderUrl,
  ) {
    if (BuiltInDohProviders.isBuiltin(dohProviderUrl) ||
        providers.any((provider) => provider.url == dohProviderUrl)) {
      return providers;
    }

    return [...providers, CustomDohProvider(url: dohProviderUrl)];
  }

  @override
  List<Object?> get hashParameters => [url, name];
}

@CopyWith()
@JsonSerializable(includeIfNull: true, constructor: 'withDefaults')
class EngineSettings extends GeckoEngineSettings with FastEquatable {
  @override
  bool get javascriptEnabled => super.javascriptEnabled!;
  @override
  TrackingProtectionPolicy get trackingProtectionPolicy =>
      super.trackingProtectionPolicy!;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  HttpsOnlyMode get httpsOnlyMode => HttpsOnlyMode.enabled;
  @override
  ColorScheme get preferredColorScheme => super.preferredColorScheme!;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get globalPrivacyControlEnabled => true;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get enterpriseRootsEnabled => false;

  /// The OS locale list, read fresh every time: the browser presents the
  /// languages the device is configured for and nothing else.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<String> get locales => WidgetsBinding.instance.platformDispatcher.locales
      .map((locale) => locale.toLanguageTag())
      .toList();

  /// Nothing reads this any more — `Core.kt` creates the runtime with the
  /// blocker lists unconditionally — but it is part of the pigeon contract, so
  /// it is answered with what that hardcoded value is.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get useContentBlockingDatabase => true;

  // What the `custom` tracking-protection policy means. There is no screen to
  // change it any more, so it is the strict answer, spelled out because the
  // native policy still has to be handed every field.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get blockCookies => true;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  CustomCookiePolicy get customCookiePolicy =>
      CustomCookiePolicy.totalProtection;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get blockTrackingContent => true;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  TrackingScope get trackingContentScope => TrackingScope.all;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get blockCryptominers => true;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get blockFingerprinters => true;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get blockRedirectTrackers => true;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get blockSuspectedFingerprinters => true;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  TrackingScope get suspectedFingerprintersScope => TrackingScope.all;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get allowListBaseline => true;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get allowListConvenience => false;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get blockAdsAnalyticsSocialTrackers => true;

  // Web content rendering. No longer user-editable: the fixed values below are
  // what the engine is told, and they leave the persisted document entirely.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get webFontsEnabled => true;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get automaticFontSizeAdjustment => true;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  double get fontSizeFactor => 1.0;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get fontInflationEnabled => false;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get inputAutoZoomEnabled => true;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get forceUserScalableContent => false;

  /// Built-in PDF viewer, always on. See the web-content block above.
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get enablePdfJs => true;

  // Process Isolation Settings (require app restart)
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get fissionEnabled => true;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get isolatedProcessEnabled => false;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get appZygoteProcessEnabled => false;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get extensionsWebAPIEnabled => true;

  // Local network access. Fixed: the gate is on, plain LAN requests are
  // allowed and tracker-like ones are not.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get lnaEnabled => true;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get lnaBlocking => false;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get lnaBlockTrackers => true;

  /// Google Safe Browsing, always on for both lists. Registered as engine
  /// preferences by the replication service.
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get safeBrowsingMalwareEnabled => true;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get safeBrowsingPhishingEnabled => true;

  /// The fingerprinting overrides the engine is given: the shipped defaults.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get fingerprintingProtectionOverrides =>
      FingerprintOverrides.defaults().toString();

  // Developer Settings
  @override
  bool get remoteDebuggingEnabled => super.remoteDebuggingEnabled!;

  @JsonKey(fromJson: _addonCollectionFromJson, toJson: _addonCollectionToJson)
  final AddonCollection? addonCollection;

  @JsonKey(
    fromJson: _ublockFilterListSettingsFromJson,
    toJson: _ublockFilterListSettingsToJson,
  )
  final UBlockFilterListSettings ublockFilterListSettings;

  final DohSettingsMode dohSettingsMode;
  final String dohProviderUrl;
  final String dohDefaultProviderUrl;
  final List<String> dohExceptionsList;

  final List<CustomDohProvider> customDohProviders;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  DohSettings get dohSettings => DohSettings(
    dohSettingsMode: dohSettingsMode,
    dohProviderUrl: dohProviderUrl,
    dohDefaultProviderUrl: dohDefaultProviderUrl,
    dohExceptionsList: dohExceptionsList,
  );

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  ContentBlocking get contentBlocking => ContentBlocking(
    queryParameterStripping: QueryParameterStripping.enabled,
    queryParameterStrippingAllowList: '',
    queryParameterStrippingStripList:
        '__hsfp __hssc __hstc __s _bhlid _branch_match_id _branch_referrer _gl _hsenc _kx _openstat at_recipient_id at_recipient_list bbeml bsft_clkid bsft_uid dclid et_rid fb_action_ids fb_comment_id fbclid gbraid gclid guce_referrer guce_referrer_sig hsCtaTracking igshid irclickid mc_eid mkt_tok ml_subscriber ml_subscriber_hash msclkid mtm_cid oft_c oft_ck oft_d oft_id oft_ids oft_k oft_lk oft_sk oly_anon_id oly_enc_id pk_cid rb_clickid s_cid sc_customer sc_eh sc_uid sms_click sms_source sms_uph srsltid ss_email_id syclid ttclid twclid unicorn_click_id vero_conv vero_id vgo_ee wbraid wickedid yclid ymclid ysclid',
    bounceTrackingProtectionMode: BounceTrackingProtectionMode.enabled,
  );

  EngineSettings({
    required super.javascriptEnabled,
    required super.trackingProtectionPolicy,
    required super.preferredColorScheme,
    required super.userAgent,
    required this.addonCollection,
    required this.ublockFilterListSettings,
    required this.dohSettingsMode,
    required this.dohProviderUrl,
    required this.dohDefaultProviderUrl,
    required this.dohExceptionsList,
    required this.customDohProviders,
    required super.displayDensityOverride,
    required super.screenWidthOverride,
    required super.screenHeightOverride,
    required super.remoteDebuggingEnabled,
  });

  EngineSettings.withDefaults({
    bool? javascriptEnabled,
    TrackingProtectionPolicy? trackingProtectionPolicy,
    ColorScheme? preferredColorScheme,
    super.userAgent,
    this.addonCollection,
    UBlockFilterListSettings? ublockFilterListSettings,
    DohSettingsMode? dohSettingsMode,
    String? dohProviderUrl,
    String? dohDefaultProviderUrl,
    List<String>? dohExceptionsList,
    List<CustomDohProvider>? customDohProviders,
    super.displayDensityOverride,
    super.screenWidthOverride,
    super.screenHeightOverride,
    bool? remoteDebuggingEnabled,
  }) : ublockFilterListSettings =
           ublockFilterListSettings ?? UBlockFilterListSettings(),
       dohSettingsMode = dohSettingsMode ?? DohSettingsMode.increased,
       dohProviderUrl = dohProviderUrl ?? BuiltInDohProviders.quad9.url,
       dohDefaultProviderUrl =
           dohDefaultProviderUrl ?? BuiltInDohProviders.quad9.url,
       dohExceptionsList = dohExceptionsList ?? [],
       customDohProviders = CustomDohProvider.adoptSelected(
         customDohProviders ?? [],
         dohProviderUrl ?? BuiltInDohProviders.quad9.url,
       ),
       super(
         javascriptEnabled: javascriptEnabled ?? true,
         trackingProtectionPolicy:
             trackingProtectionPolicy ?? TrackingProtectionPolicy.strict,
         preferredColorScheme: preferredColorScheme ?? ColorScheme.system,
         webFontsEnabled: true,
         automaticFontSizeAdjustment: true,
         fontSizeFactor: 1.0,
         fontInflationEnabled: false,
         inputAutoZoomEnabled: true,
         forceUserScalableContent: false,
         remoteDebuggingEnabled: remoteDebuggingEnabled ?? false,
       );

  static AddonCollection? _addonCollectionFromJson(String? json) =>
      json.mapNotNull(
        (collection) => AddonCollection.decode(jsonDecode(collection) as List),
      );

  static String? _addonCollectionToJson(AddonCollection? collection) =>
      collection.mapNotNull((collection) => jsonEncode(collection.encode()));

  static UBlockFilterListSettings _ublockFilterListSettingsFromJson(
    String? json,
  ) =>
      json.mapNotNull(
        (encoded) => UBlockFilterListSettings.fromJson(
          jsonDecode(encoded) as Map<String, dynamic>,
        ),
      ) ??
      UBlockFilterListSettings();

  static String _ublockFilterListSettingsToJson(
    UBlockFilterListSettings settings,
  ) => jsonEncode(settings.toJson());

  factory EngineSettings.fromJson(Map<String, dynamic> json) =>
      _$EngineSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$EngineSettingsToJson(this);

  @override
  List<Object?> get hashParameters => [
    javascriptEnabled,
    trackingProtectionPolicy,
    preferredColorScheme,
    userAgent,
    addonCollection,
    ublockFilterListSettings,
    dohSettingsMode,
    dohProviderUrl,
    dohDefaultProviderUrl,
    dohExceptionsList,
    customDohProviders,
    displayDensityOverride,
    screenWidthOverride,
    screenHeightOverride,
    remoteDebuggingEnabled,
  ];
}
