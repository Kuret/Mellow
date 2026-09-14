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
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:fast_equatable/fast_equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:weblibre/features/user/data/models/general_settings.dart'
    show TabBarPosition;

part 'zen_settings.g.dart';

/// Bounds of [ZenSettings.maxLiveTabs] (PLAN §7.4 item 5).
const defaultMaxLiveTabs = 25;
const minMaxLiveTabs = 5;
const maxMaxLiveTabs = 100;

/// Defaults of the destructive-batch canary (DESIGN "Hardening against Zen's
/// stale-projection race", defence 5).
const defaultSpacesSyncMaxTombstoneFraction = 0.2;
const defaultSpacesSyncMaxTombstoneCount = 25;

/// Width (logical px) of the side rail on wide viewports. The rail is always
/// the expanded Arc/Zen-style sidebar — address row, shelves, toolbar, space
/// switcher — so it needs room for a favicon and a title side by side;
/// [minRailWidth] is the least that reads. A stored value below it (from the
/// days of an icon-only rail) is clamped up on read, see [effectiveRailWidth].
const defaultRailWidth = 260.0;
const minRailWidth = 160.0;
const maxRailWidth = 320.0;
const railWidthStep = 8.0;

/// Which edge the wide-viewport side rail docks to. Independent of
/// [TabBarPosition], which only places the narrow-viewport compact bar.
enum RailSide { left, right }

/// Viewport width, in logical px, from which the browser lays its chrome out
/// as the side rail ([RailSide]) instead of the compact horizontal bar
/// ([TabBarPosition]): tablets, landscape and unfolded foldables clear it;
/// phones in portrait and folded foldables get the bar. Decided per frame
/// from the viewport, so rotating or unfolding switches live.
const narrowRailViewportBreakpoint = 600.0;

/// Whether a viewport of [viewportWidth] gets the side rail layout.
bool isWideViewport(double viewportWidth) =>
    viewportWidth >= narrowRailViewportBreakpoint;

/// Content width of the side rail: [railWidth] clamped into
/// [minRailWidth]..[maxRailWidth]. The lower bound rose when the icon-only
/// rail was retired, so a stored width from before then is pulled up to the
/// least the expanded rail can show.
double effectiveRailWidth({required double railWidth}) =>
    railWidth.clamp(minRailWidth, maxRailWidth);

/// The edge the browser chrome occupies on a viewport of [viewportWidth]: the
/// side rail's [railSide] on a wide viewport ([isWideViewport]), the compact
/// bar's [narrowPosition] on a narrow one. The layers of the browser screen
/// share [TabBarPosition] as their edge vocabulary, so the rail answers with
/// its (legacy) left/right values.
TabBarPosition chromeEdge({
  required double viewportWidth,
  required RailSide railSide,
  required TabBarPosition narrowPosition,
}) {
  if (isWideViewport(viewportWidth)) {
    return switch (railSide) {
      RailSide.left => TabBarPosition.left,
      RailSide.right => TabBarPosition.right,
    };
  }
  return narrowPosition;
}

/// The settings this fork owns: the Zen Spaces sync client's switches and
/// bookkeeping, and the Zen tab model's rail and tab-budget options.
///
/// They live here rather than on `GeneralSettings` on purpose. That model is
/// upstream WebLibre's, one of its hottest files, so every field we added to
/// it turned into a merge conflict on the next upstream settings change. This
/// model is ours alone; it is stored in the same `setting` table under the
/// `zen` partition key.
@CopyWith()
@JsonSerializable(includeIfNull: true, constructor: 'withDefaults')
class ZenSettings with FastEquatable {
  /// Whether the Zen Spaces sync client runs at all. Inert without a Firefox
  /// account (PLAN §8).
  final bool spacesSyncEnabled;

  /// The kill switch (PLAN §8.6 item 6): when off, the spaces client keeps
  /// reading the collection but uploads nothing.
  final bool spacesSyncWritesEnabled;

  /// `meta/global.engines.spaces.syncID` last seen; a change resets local
  /// sync state (PLAN §8.3 item 4).
  final String? spacesSyncLastSyncId;

  /// The `spaces` collection's last-modified timestamp (seconds) this device
  /// has fetched up to.
  final double? spacesSyncLastModified;

  /// Whether a full baseline of the collection has been fetched and applied;
  /// until then no tombstone is ever uploaded (PLAN §8.6 item 4).
  final bool spacesSyncBaselineDone;

  /// The `spacesApplierVersion` whose rules every applied record on this
  /// device follows; a mismatch makes the next sync refetch and re-apply the
  /// whole collection. `0` until the first sync after the field appeared.
  final int spacesSyncApplierVersion;

  /// Destructive-batch canary (DESIGN "Hardening against Zen's stale-projection
  /// race", defence 5): the largest share of the syncable tabs one sync may
  /// tombstone before the whole upload is refused and surfaced to the user.
  /// Clamped to 0..1.
  final double spacesSyncMaxTombstoneFraction;

  /// The absolute companion to [spacesSyncMaxTombstoneFraction]: the effective
  /// limit is the smaller of the two, so a huge tab count cannot turn 20 % into
  /// a harmless-looking number. Clamped to >= 0.
  final int spacesSyncMaxTombstoneCount;

  /// Which edge the side rail docks to on wide viewports. See [RailSide].
  final RailSide railSide;

  /// Width (logical px) of the vertical tab bar side rail. See
  /// [defaultRailWidth].
  final double railWidth;

  /// How many tabs may hold a live engine session at once (PLAN §7.4). Above
  /// it, `LiveTabBudget` unloads the least recently used regular tabs back to
  /// cold rows. Clamped to [minMaxLiveTabs]..[maxMaxLiveTabs]; defaults to
  /// [defaultMaxLiveTabs].
  final int maxLiveTabs;

  /// Local stand-in for Zen's `zen.workspaces.separate-essentials`
  /// (PLAN §6.4, DESIGN.md OPEN-3): with it on, the Essentials strip is keyed
  /// on the current space's container; with it off, every essential shows in
  /// every space.
  final bool separateEssentials;

  ZenSettings({
    required this.spacesSyncEnabled,
    required this.spacesSyncWritesEnabled,
    required this.spacesSyncLastSyncId,
    required this.spacesSyncLastModified,
    required this.spacesSyncBaselineDone,
    required this.spacesSyncApplierVersion,
    required this.spacesSyncMaxTombstoneFraction,
    required this.spacesSyncMaxTombstoneCount,
    required this.railSide,
    required this.railWidth,
    required this.maxLiveTabs,
    required this.separateEssentials,
  });

  ZenSettings.withDefaults({
    bool? spacesSyncEnabled,
    bool? spacesSyncWritesEnabled,
    this.spacesSyncLastSyncId,
    this.spacesSyncLastModified,
    bool? spacesSyncBaselineDone,
    int? spacesSyncApplierVersion,
    double? spacesSyncMaxTombstoneFraction,
    int? spacesSyncMaxTombstoneCount,
    RailSide? railSide,
    double? railWidth,
    int? maxLiveTabs,
    bool? separateEssentials,
  }) : spacesSyncEnabled = spacesSyncEnabled ?? true,
       spacesSyncWritesEnabled = spacesSyncWritesEnabled ?? true,
       spacesSyncBaselineDone = spacesSyncBaselineDone ?? false,
       spacesSyncApplierVersion = spacesSyncApplierVersion ?? 0,
       spacesSyncMaxTombstoneFraction =
           (spacesSyncMaxTombstoneFraction ??
                   defaultSpacesSyncMaxTombstoneFraction)
               .clamp(0.0, 1.0),
       spacesSyncMaxTombstoneCount =
           (spacesSyncMaxTombstoneCount ?? defaultSpacesSyncMaxTombstoneCount)
               .clamp(0, 1 << 30),
       railSide = railSide ?? RailSide.left,
       railWidth = (railWidth ?? defaultRailWidth).clamp(
         minRailWidth,
         maxRailWidth,
       ),
       maxLiveTabs = (maxLiveTabs ?? defaultMaxLiveTabs).clamp(
         minMaxLiveTabs,
         maxMaxLiveTabs,
       ),
       separateEssentials = separateEssentials ?? true;

  factory ZenSettings.fromJson(Map<String, dynamic> json) =>
      _$ZenSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$ZenSettingsToJson(this);

  @override
  List<Object?> get hashParameters => [
    spacesSyncEnabled,
    spacesSyncWritesEnabled,
    spacesSyncLastSyncId,
    spacesSyncLastModified,
    spacesSyncBaselineDone,
    spacesSyncApplierVersion,
    spacesSyncMaxTombstoneFraction,
    spacesSyncMaxTombstoneCount,
    railSide,
    railWidth,
    maxLiveTabs,
    separateEssentials,
  ];
}
