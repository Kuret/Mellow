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
import 'dart:async';

import 'package:flutter_mozilla_components/flutter_mozilla_components.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:synchronized/synchronized.dart';
import 'package:weblibre/core/logger.dart';
import 'package:weblibre/features/app_links/domain/entities/app_link_rule.dart';
import 'package:weblibre/features/user/domain/repositories/general_settings.dart';

part 'app_link_policy_replication.g.dart';

/// The complete policy snapshot to push, or null until the real persisted
/// settings have loaded. Combines the user-intent settings with the (now
/// constant) protection fields — proxy routing, container strict mode and
/// per-container app-link overrides have all been removed, so nothing is
/// ever protected or overridden any more, but the native pigeon contract
/// still expects these fields on every snapshot.
@Riverpod(keepAlive: true)
AppLinkPolicySnapshot? appLinkPolicySnapshot(Ref ref) {
  final settings = ref.watch(generalSettingsRepositoryProvider).value;
  if (settings == null) return null;

  return AppLinkPolicySnapshot(
    globalMode: settings.appLinksMode,
    rules: {
      for (final MapEntry(:key, :value) in settings.appLinkRules.entries)
        key: _toNativeRule(value),
    },
    marketplaceFallbackEnabled: false,
    authExceptionsEnabled: true,
    blockWhilePrompting: false,
    protectGeneralContext: false,
    protectedContextIds: const [],
    strictContextIds: const [],
    protectedTargetPatterns: const [],
    contextOverrides: const {},
  );
}

NativeAppLinkRule _toNativeRule(PersistedAppLinkRule rule) {
  return NativeAppLinkRule(
    decision: switch (rule.decision) {
      AppLinkRuleDecision.alwaysOpen => NativeAppLinkRuleDecision.alwaysOpen,
      AppLinkRuleDecision.neverOpen => NativeAppLinkRuleDecision.neverOpen,
    },
    scope: rule.scope,
    packageName: rule.packageName,
  );
}

/// Single serialised writer that mirrors the Dart-owned app-link policy to the
/// native profile-scoped store (§2.8), the sole policy source consulted by the
/// interceptor. Structured like `ProxySettingsReplication`; mounted from app root
/// after initialisation.
@Riverpod(keepAlive: true)
class AppLinkPolicyReplication extends _$AppLinkPolicyReplication {
  final _appLinks = GeckoAppLinksService();

  final _pushLock = Lock();
  // Coalesces the most recent snapshot while a push is in flight; genuinely
  // nullable (no snapshot pushed yet).
  // ignore: use_late_for_private_fields_and_variables
  AppLinkPolicySnapshot? _latest;
  var _pushDirty = false;

  Future<void> _queuePush(AppLinkPolicySnapshot snapshot) async {
    _latest = snapshot;
    _pushDirty = true;
    if (_pushLock.inLock) return;

    await _pushLock.synchronized(() async {
      while (_pushDirty) {
        _pushDirty = false;
        final pending = _latest!;
        try {
          await _appLinks.setAppLinkPolicy(pending);
        } catch (error, stackTrace) {
          // `setAppLinkPolicy` before a profile is bound is an error the
          // replicator retries after initialisation (§2.8).
          logger.w(
            'Failed to push app-link policy; will retry',
            error: error,
            stackTrace: stackTrace,
          );
          _pushDirty = true;
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
    });
  }

  @override
  void build() {
    ref.listen(
      fireImmediately: true,
      appLinkPolicySnapshotProvider,
      (previous, next) {
        if (next == null) return;
        unawaited(_queuePush(next));
      },
      onError: (error, stackTrace) {
        logger.e(
          'Error computing app-link policy snapshot',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }
}
