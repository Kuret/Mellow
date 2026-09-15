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
import 'dart:io';

import 'package:mellow/features/spaces_sync/data/models/zen_records.dart';
import 'package:path/path.dart' as p;

/// One saved copy of the decrypted `spaces` collection.
class SpacesSnapshot {
  SpacesSnapshot({required this.file, required this.takenAt});

  final File file;
  final DateTime takenAt;
}

/// The escape hatch (PLAN §8.6 item 7): before this profile's first upload
/// the whole decrypted collection is written to
/// `<profile>/spaces_sync/snapshot-<epochMillis>.json` as a cleartext JSON
/// array, and the last [keep] files are retained. If a sync ever corrupts
/// the desktop, restoring one of these is the fastest fix.
class SnapshotStore {
  SnapshotStore(this.directory, {this.keep = 3});

  final Directory directory;
  final int keep;

  static const _prefix = 'snapshot-';
  static const _suffix = '.json';

  static const _failedFileName = 'failed-ids.json';

  Future<SpacesSnapshot> write(
    Iterable<Map<String, Object?>> cleartexts, {
    DateTime? now,
  }) async {
    await directory.create(recursive: true);
    final takenAt = now ?? DateTime.now();
    final file = File(
      p.join(
        directory.path,
        '$_prefix${takenAt.millisecondsSinceEpoch}$_suffix',
      ),
    );
    await file.writeAsString(jsonEncode(cleartexts.toList(growable: false)));
    await _prune();
    return SpacesSnapshot(file: file, takenAt: takenAt);
  }

  /// Newest first.
  Future<List<SpacesSnapshot>> list() async {
    if (!await directory.exists()) {
      return const [];
    }
    final snapshots = <SpacesSnapshot>[];
    await for (final entity in directory.list()) {
      if (entity is! File) {
        continue;
      }
      final name = p.basename(entity.path);
      if (!name.startsWith(_prefix) || !name.endsWith(_suffix)) {
        continue;
      }
      final millis = int.tryParse(
        name.substring(_prefix.length, name.length - _suffix.length),
      );
      if (millis == null) {
        continue;
      }
      snapshots.add(
        SpacesSnapshot(
          file: entity,
          takenAt: DateTime.fromMillisecondsSinceEpoch(millis),
        ),
      );
    }
    snapshots.sort((a, b) => b.takenAt.compareTo(a.takenAt));
    return snapshots;
  }

  /// Decodes a snapshot back into incoming records.
  Future<List<ZenIncoming>> read(SpacesSnapshot snapshot) async {
    final decoded = jsonDecode(await snapshot.file.readAsString());
    if (decoded is! List) {
      throw const FormatException('snapshot is not a JSON array');
    }
    return [
      for (final element in decoded)
        ZenRecordCodec.decode((element as Map).cast<String, Object?>()),
    ];
  }

  Future<void> _prune() async {
    final snapshots = await list();
    for (final stale in snapshots.skip(keep)) {
      await stale.file.delete();
    }
  }

  // --- previously failed ids -------------------------------------------------

  File get _failedFile => File(p.join(directory.path, _failedFileName));

  /// Ids whose records failed to apply on an earlier sync and must be
  /// re-fetched by id, since `newer=` will not deliver them again
  /// (Firefox's `previousFailed`).
  Future<Set<String>> readFailedIds() async {
    if (!await _failedFile.exists()) {
      return {};
    }
    try {
      final decoded = jsonDecode(await _failedFile.readAsString());
      return {for (final id in decoded as List) id as String};
    } on FormatException {
      return {};
    }
  }

  Future<void> writeFailedIds(Set<String> ids) async {
    if (ids.isEmpty) {
      if (await _failedFile.exists()) {
        await _failedFile.delete();
      }
      return;
    }
    await directory.create(recursive: true);
    await _failedFile.writeAsString(jsonEncode(ids.toList()..sort()));
  }
}
