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
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/core/copy/profile_copy.dart';
import 'package:mellow/core/filesystem.dart';
import 'package:mellow/core/routing/routes.dart';
import 'package:mellow/domain/entities/profile.dart';
import 'package:mellow/features/settings/presentation/widgets/sections.dart';
import 'package:mellow/features/user/data/models/auth_settings.dart';
import 'package:mellow/features/user/domain/entities/restart_cost.dart';
import 'package:mellow/features/user/domain/presentation/dialogs/profile_maintenance_dialogs.dart';
import 'package:mellow/features/user/domain/presentation/dialogs/profile_password_dialogs.dart';
import 'package:mellow/features/user/domain/presentation/utils/profile_authorization.dart';
import 'package:mellow/features/user/domain/presentation/utils/profile_switch_handler.dart';
import 'package:mellow/features/user/domain/providers/profile_auth.dart';
import 'package:mellow/features/user/domain/repositories/profile.dart';
import 'package:mellow/features/user/domain/services/local_authentication.dart';
import 'package:mellow/utils/exit_app.dart';
import 'package:mellow/utils/form_validators.dart';
import 'package:mellow/utils/ui_helper.dart';

/// Scope for the confirmation taken *before* a locked profile exists.
///
/// Deliberately not a per-profile key: there is no profile id yet, and the value
/// only scopes `LocalAuthenticationService`'s result cache.
const _newProfileAuthKey = 'profile_access::pending';

const _timeoutOptions = <DropdownMenuItem<Duration?>>[
  DropdownMenuItem(value: Duration(minutes: 1), child: Text('1 minute')),
  DropdownMenuItem(value: Duration(minutes: 5), child: Text('5 minutes')),
  DropdownMenuItem(value: Duration(minutes: 15), child: Text('15 minutes')),
  DropdownMenuItem(value: Duration(hours: 1), child: Text('1 hour')),
];

class ProfileEditScreen extends HookConsumerWidget {
  final Profile? profile;

  const ProfileEditScreen({super.key, required this.profile});

  Future<void> _handleSave(
    BuildContext context,
    WidgetRef ref,
    GlobalKey<FormState> formKey,
    String name,
    AuthSettings authSettings,
  ) async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Read from disk rather than trusted from the route: what guards a profile
    // has to be what the profile says now.
    final existing = profile != null
        ? await readCurrentProfileMetadata(profile!)
        : null;
    if (!context.mounted) return;

    void reportFailure() {
      showErrorMessage(
        context,
        existing != null
            ? 'Could not confirm your identity. $nothingChanged'
            : 'Could not confirm your identity. A locked profile is only '
                  'created once this device can unlock it.',
      );
    }

    // Any change to a locked profile — its name included — needs whatever
    // unlocks it now. Otherwise anyone with another profile open could reach
    // this screen from the profile list and simply switch the lock off.
    if (existing != null && existing.authSettings.authenticationRequired) {
      final authorized = await authorizeProfileAction(
        context,
        ref,
        existing,
        reason: 'Change "${existing.name}"',
      );
      if (!context.mounted) return;
      if (!authorized) {
        reportFailure();
        return;
      }
    }

    // Prove the device prompt works before it becomes the lock — including on
    // the *create* path, which used to skip it because there was no existing
    // profile to compare against. Skipping it meant a user could switch the
    // lock on with nothing enrolled on the device: `authenticate` catches
    // `LocalAuthException` and reports failure, and the result was a profile
    // that could never be opened. Already proved above when the profile was
    // device-locked before.
    final provesDevice =
        authSettings.lockMethod == ProfileLockMethod.device &&
        existing?.authSettings.lockMethod != ProfileLockMethod.device;

    if (provesDevice) {
      final alsoRemember = await activeProfileDeviceUnlock(existing);
      if (!context.mounted) return;

      final authResult = await ref
          .read(localAuthenticationServiceProvider.notifier)
          .authenticate(
            // A profile being created has no id yet, and the key only scopes the
            // result cache — nothing has been created for it to belong to.
            authKey: existing != null
                ? profileAccessAuthKey(existing.id)
                : _newProfileAuthKey,
            localizedTitle: deviceAuthPromptTitle,
            localizedReason: existing != null
                ? 'Require authentication for profile'
                : 'Confirm you can unlock this profile',
            settings: authSettings,
            alsoRemember: alsoRemember,
          );

      if (!authResult.passed) {
        if (context.mounted) reportFailure();
        return;
      }
    }

    // The editor only offers the password method together with a password,
    // so this is a guard against a lock nobody could open, not a UI path.
    if (authSettings.lockMethod == ProfileLockMethod.password &&
        authSettings.passwordVerifier == null) {
      return;
    }

    // A verifier left behind by a method that no longer uses it would come
    // back to life, with the old password, the next time the method is chosen.
    final toSave = authSettings.lockMethod == ProfileLockMethod.password
        ? authSettings
        : authSettings.copyWith(passwordVerifier: null);

    if (profile != null) {
      await ref
          .read(profileRepositoryProvider.notifier)
          .updateProfileMetadata(
            existing!.copyWith(name: name, authSettings: toSave),
          );

      // The remembered unlock carries the auto-lock policy it was made under,
      // and `isCached`/`evictCacheOnBackground` read that copy rather than the
      // profile. Left alone, a switch from "on startup" to "in background"
      // would never lock this session. Every path above proved the new lock —
      // the old one was answered, the device prompt passed, or the password
      // was just typed twice — so the open profile stays unlocked, under the
      // new policy from now on.
      final authCache = ref.read(localAuthenticationServiceProvider.notifier);
      final authKey = profileAccessAuthKey(existing.id);
      if (existing.uuidValue == filesystem.selectedProfile &&
          toSave.authenticationRequired) {
        authCache.remember(authKey, toSave);
      } else {
        authCache.forget(authKey);
      }

      if (context.mounted) {
        context.pop();
      }
    } else {
      await ref
          .read(profileRepositoryProvider.notifier)
          .createProfile(name: name, authSettings: toSave);

      if (context.mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameTextController = useTextEditingController(text: profile?.name);
    final authSettings = useState(
      profile?.authSettings ?? AuthSettings.withDefaults(),
    );

    return Scaffold(
      appBar: AppBar(
        title: (profile != null)
            ? const Text('Edit Profile')
            : const Text('Create Profile'),
        actions: [
          IconButton(
            onPressed: () async {
              await _handleSave(
                context,
                ref,
                formKey,
                nameTextController.text,
                authSettings.value,
              );
            },
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            children: [
              TextFormField(
                controller: nameTextController,
                decoration: const InputDecoration(
                  label: Text('Name'),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                validator: validateProfileName,
              ),
              const SizedBox(height: 24),
              _AuthSection(
                authSettings: authSettings.value,
                onAuthSettingsChanged: (newSettings) {
                  authSettings.value = newSettings;
                },
              ),
              const SizedBox(height: 24),
              if (profile != null) ...[
                _ProfileActionsSection(profile: profile!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthSection extends StatelessWidget {
  final AuthSettings authSettings;
  final ValueChanged<AuthSettings> onAuthSettingsChanged;

  const _AuthSection({
    required this.authSettings,
    required this.onAuthSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingSection(name: 'Authentication'),
        RadioGroup<ProfileLockMethod>(
          groupValue: authSettings.lockMethod,
          onChanged: (value) async {
            if (value == null) return;

            // Chosen only together with a password. A password method with no
            // password behind it is a profile nobody can open.
            if (value == ProfileLockMethod.password &&
                authSettings.passwordVerifier == null) {
              final verifier = await showSetProfilePasswordDialog(context);
              if (verifier == null || !context.mounted) return;

              onAuthSettingsChanged(
                authSettings.copyWith(
                  lockMethod: value,
                  passwordVerifier: verifier,
                ),
              );
              return;
            }

            onAuthSettingsChanged(authSettings.copyWith.lockMethod(value));
          },
          child: const Column(
            children: [
              RadioListTile.adaptive(
                value: ProfileLockMethod.none,
                title: Text('No lock'),
                subtitle: Text(
                  'Anyone using Mellow on this device can open this profile',
                ),
                secondary: Icon(MdiIcons.lockOpenVariantOutline),
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile.adaptive(
                value: ProfileLockMethod.device,
                title: Text('Device lock'),
                subtitle: Text(
                  'Fingerprint, face or the device PIN. Anyone who can unlock '
                  'this device can open this profile.',
                ),
                secondary: Icon(MdiIcons.fingerprint),
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile.adaptive(
                value: ProfileLockMethod.password,
                title: Text('Profile password'),
                subtitle: Text(
                  "A password only for this profile. Fingerprints and the "
                  "device PIN can't open it.",
                ),
                secondary: Icon(MdiIcons.formTextboxPassword),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        if (authSettings.lockMethod == ProfileLockMethod.password) ...[
          ListTile(
            title: const Text('Change password'),
            leading: const Icon(MdiIcons.keyChange),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            onTap: () async {
              final verifier = await showSetProfilePasswordDialog(context);
              if (verifier == null || !context.mounted) return;

              onAuthSettingsChanged(
                authSettings.copyWith.passwordVerifier(verifier),
              );
            },
          ),
          const ListTile(
            title: Text("A forgotten password can't be recovered"),
            subtitle: Text(
              "Without it, this profile can't be opened, backed up or "
              "deleted. The password locks Mellow; it does not encrypt the "
              "profile's data.",
            ),
            leading: Icon(Icons.info_outline),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
          ),
        ],
        if (authSettings.authenticationRequired) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  title: Text('Auto-lock'),
                  subtitle: Text('When to lock the profile again'),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(MdiIcons.lockClock),
                ),
                RadioGroup<AutoLockMode>(
                  groupValue: authSettings.autoLockMode,
                  onChanged: (value) {
                    if (value != null) {
                      onAuthSettingsChanged(
                        authSettings.copyWith.autoLockMode(value),
                      );
                    }
                  },
                  child: const Column(
                    children: [
                      RadioListTile.adaptive(
                        value: AutoLockMode.background,
                        title: Text('Lock in background'),
                        subtitle: Text('As soon as Mellow leaves the screen'),
                      ),
                      RadioListTile.adaptive(
                        value: AutoLockMode.timeout,
                        title: Text('Lock after a timeout'),
                        subtitle: Text('After a period of inactivity'),
                      ),
                      RadioListTile.adaptive(
                        value: AutoLockMode.startup,
                        title: Text('Lock on startup only'),
                        subtitle: Text(
                          'Unlock once at startup, then stay unlocked until '
                          'Mellow is fully closed',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (authSettings.autoLockMode == AutoLockMode.timeout)
            ListTile(
              title: const Text('Timeout'),
              subtitle: const Text('How long to wait before locking'),
              leading: const Icon(MdiIcons.timerOutline),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              trailing: DropdownButton<Duration?>(
                value: authSettings.timeout,
                items: _timeoutOptions,
                underline: const SizedBox.shrink(),
                onChanged: (Duration? value) {
                  if (value != null) {
                    onAuthSettingsChanged(authSettings.copyWith.timeout(value));
                  }
                },
              ),
            ),
        ],
      ],
    );
  }
}

class _ProfileActionsSection extends ConsumerWidget {
  final Profile profile;

  const _ProfileActionsSection({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Backup is offered for every profile, the active one included: it does not
    // run here at all — it is queued and taken by the next process, with the
    // profile closed. Switching and deleting are the two that genuinely cannot
    // act on the profile this process is serving, so they are left out rather
    // than shown to fail.
    final isActive = filesystem.selectedProfile == profile.uuidValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingSection(name: 'Profile actions'),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            label: const Text('Backup'),
            icon: const Icon(MdiIcons.safe),
            onPressed: () async {
              await BackupProfileRoute(
                profile: jsonEncode(profile.toJson()),
              ).push(context);
            },
          ),
        ),
        if (isActive)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Switching and deleting are unavailable for the profile you '
              'are using.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              label: const Text('Switch to this profile'),
              icon: const Icon(MdiIcons.accountSwitch),
              onPressed: () async {
                await handleSwitchProfile(context, ref, profile);
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.error),
                foregroundColor: Theme.of(context).colorScheme.error,
                iconColor: Theme.of(context).colorScheme.error,
              ),
              label: const Text('Delete'),
              icon: const Icon(Icons.delete),
              onPressed: () async {
                // Read before the dialog opens, not inside it: counts that
                // arrive a frame late land on a dialog the user has already
                // started tapping through.
                final restartCost = await readRestartCost(ref);
                if (!context.mounted) return;

                final result = await showDeleteProfileDialog(
                  context,
                  profileName: profile.name,
                  restartCost: restartCost,
                );

                if (result != true || !context.mounted) return;

                // Deleting destroys nothing that leaves the device, but it
                // is still someone else's profile when this runs from another
                // one, and a lock that anyone could delete away is no lock.
                final authorized = await authorizeProfileAction(
                  context,
                  ref,
                  profile,
                  reason: 'Delete "${profile.name}"',
                );

                if (authorized) {
                  // Queues the delete and restarts: a profile's state reaches
                  // beyond its directory, so removal needs an ownership snapshot
                  // and a journal, and both need a maintenance lease this process
                  // cannot hold while it is running the browser.
                  final bool queued;
                  try {
                    queued = await ref
                        .read(profileRepositoryProvider.notifier)
                        .deleteProfile(profile.uuidValue.uuid);
                  } catch (error) {
                    // Queued and then unqueued: the restart it needs could not be
                    // scheduled. Caught here because nothing above a button's
                    // handler would, and an uncaught error means the user taps
                    // "Delete" on a confirmed dialog and watches nothing happen.
                    if (context.mounted) {
                      showErrorMessage(context, 'Could not delete: $error');
                    }
                    return;
                  }

                  if (queued) {
                    await exitApp(ref.container, restart: true);
                  } else if (context.mounted) {
                    // Refused rather than failed — the profile is gone already or
                    // its metadata is too damaged to discover. Saying so beats a
                    // screen that just closes after a confirmed delete.
                    showErrorMessage(context, 'Could not delete this profile');
                    context.pop();
                  }
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}
