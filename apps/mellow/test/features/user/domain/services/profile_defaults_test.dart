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
import 'package:flutter_test/flutter_test.dart';
import 'package:mellow/features/geckoview/features/preferences/data/models/preference_setting.dart';
import 'package:mellow/features/user/data/models/ublock_filter_list_settings.dart';
import 'package:mellow/features/user/domain/services/profile_defaults.dart';

PreferenceSetting _setting(Object value, {bool requireUserOptIn = false}) {
  return PreferenceSetting(
    value: value,
    title: 'title',
    description: 'description',
    requireUserOptIn: requireUserOptIn,
  );
}

void main() {
  group('isPristineUBlockFilterListSettings', () {
    test('is true for the model default', () {
      expect(
        isPristineUBlockFilterListSettings(UBlockFilterListSettings()),
        isTrue,
      );
    });

    test('is false once enabled', () {
      expect(
        isPristineUBlockFilterListSettings(
          UBlockFilterListSettings(enabled: true),
        ),
        isFalse,
      );
    });

    test('is false once a stock list is manually enabled', () {
      expect(
        isPristineUBlockFilterListSettings(
          UBlockFilterListSettings(enabledStockListTokens: const ['easylist']),
        ),
        isFalse,
      );
    });

    test('is false once a stock list is auto-enabled', () {
      expect(
        isPristineUBlockFilterListSettings(
          UBlockFilterListSettings(
            autoEnabledStockListTokens: const ['easylist'],
          ),
        ),
        isFalse,
      );
    });

    test('is false once an external filter list is added', () {
      expect(
        isPristineUBlockFilterListSettings(
          UBlockFilterListSettings(
            externalFilterLists: [
              UBlockExternalList(url: 'https://example.com/list.txt'),
            ],
          ),
        ),
        isFalse,
      );
    });
  });

  group('selectDefaultHardeningPrefs', () {
    test('omits the opt-in-only groups entirely', () {
      final groups = {
        'Resist Fingerprinting': PreferenceSettingGroup(
          description: null,
          settings: {'privacy.resistFingerprinting': _setting(true)},
        ),
        'WebGL': PreferenceSettingGroup(
          description: null,
          settings: {'webgl.disabled': _setting(true)},
        ),
        'Attack Surface Reduction': PreferenceSettingGroup(
          description: null,
          settings: {
            'javascript.options.main_process_disable_jit': _setting(true),
          },
        ),
        'Telemetry': PreferenceSettingGroup(
          description: null,
          settings: {'toolkit.telemetry.enabled': _setting(false)},
        ),
      };

      final result = selectDefaultHardeningPrefs(groups, {});

      expect(result.keys, ['toolkit.telemetry.enabled']);
    });

    test('omits prefs that require explicit user opt-in', () {
      final groups = {
        'Telemetry': PreferenceSettingGroup(
          description: null,
          settings: {
            'toolkit.telemetry.enabled': _setting(false),
            'toolkit.telemetry.optional': _setting(
              true,
              requireUserOptIn: true,
            ),
          },
        ),
      };

      final result = selectDefaultHardeningPrefs(groups, {});

      expect(result.keys, ['toolkit.telemetry.enabled']);
    });

    test('omits prefs the profile has already changed on the user branch', () {
      final groups = {
        'Telemetry': PreferenceSettingGroup(
          description: null,
          settings: {'toolkit.telemetry.enabled': _setting(false)},
        ),
      };

      final result = selectDefaultHardeningPrefs(groups, {
        'toolkit.telemetry.enabled',
      });

      expect(result, isEmpty);
    });

    test('includes a pref the profile has never touched', () {
      final groups = {
        'Telemetry': PreferenceSettingGroup(
          description: null,
          settings: {'toolkit.telemetry.enabled': _setting(false)},
        ),
      };

      final result = selectDefaultHardeningPrefs(groups, {'some.other.pref'});

      expect(result, {'toolkit.telemetry.enabled': false});
    });

    test('includes a pref absent from the current-prefs map entirely', () {
      final groups = {
        'Telemetry': PreferenceSettingGroup(
          description: null,
          settings: {'toolkit.telemetry.enabled': _setting(false)},
        ),
      };

      final result = selectDefaultHardeningPrefs(groups, <String>{});

      expect(result, {'toolkit.telemetry.enabled': false});
    });
  });
}
