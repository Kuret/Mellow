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
import 'package:weblibre/features/spaces_sync/data/models/zen_records.dart';

/// One reason a record in an outgoing batch was refused.
class BatchViolation {
  const BatchViolation({required this.recordId, required this.reason});

  final String recordId;
  final String reason;

  @override
  String toString() => '$recordId: $reason';
}

/// The result of [validateOutgoingBatch]: either the batch is clean, or it
/// carries every violation found (all of them — this is a report, not a
/// fail-fast check, so a caller logging the refusal has the full picture).
sealed class BatchValidationResult {
  const BatchValidationResult();
}

/// No violations: the batch may be uploaded.
final class BatchValidationOk extends BatchValidationResult {
  const BatchValidationOk();
}

/// At least one violation: PLAN §8.6 item 2 says refuse the *whole* batch,
/// not just the offending records.
final class BatchValidationRejected extends BatchValidationResult {
  const BatchValidationRejected(this.violations);

  final List<BatchViolation> violations;
}

/// Validates an outgoing batch of live records before it leaves the device
/// (PLAN §8.6 item 2) — the foreign-client safety net. A malformed record
/// here corrupts the user's desktop sidebar rather than failing safe, so
/// every check below is a hard prerequisite for the write, not a lint.
///
/// [knownIds] / [knownContainerGuids] are whatever this device already
/// believes exists (from the last reconciled state); ids/guids introduced by
/// this same batch also resolve, since a batch may create a space and
/// populate its children in one pass.
BatchValidationResult validateOutgoingBatch(
  List<ZenCleartext> records, {
  required Set<String> knownIds,
  required Set<String> knownContainerGuids,
}) {
  final violations = <BatchViolation>[];

  final batchIds = {for (final record in records) record.id};
  final batchContainerGuids = {
    for (final record in records)
      if (record.data case ZenContainerRecord(:final guid)) guid,
  };
  final resolvableIds = {...knownIds, ...batchIds};
  final resolvableContainerGuids = {
    ...knownContainerGuids,
    ...batchContainerGuids,
  };

  void checkChildId(String recordId, String childId) {
    if (!resolvableIds.contains(childId)) {
      violations.add(
        BatchViolation(
          recordId: recordId,
          reason: 'child id "$childId" does not resolve',
        ),
      );
    }
  }

  void checkContainerGuid(String recordId, String? guid) {
    if (guid != null && !resolvableContainerGuids.contains(guid)) {
      violations.add(
        BatchViolation(
          recordId: recordId,
          reason: 'containerGuid "$guid" does not exist',
        ),
      );
    }
  }

  for (final record in records) {
    if (record.data.recordId != record.id) {
      violations.add(
        BatchViolation(
          recordId: record.id,
          reason:
              'recordId "${record.data.recordId}" does not match cleartext '
              'id "${record.id}"',
        ),
      );
    }

    switch (record.data) {
      case ZenContainerRecord():
        break;

      case ZenForeignRecord():
        // Another client's record, re-emitted verbatim: nothing to check.
        break;

      case ZenSpaceRecord(:final children, :final containerGuid):
        for (final childId in children) {
          checkChildId(record.id, childId);
        }
        checkContainerGuid(record.id, containerGuid);

      case ZenTabRecord(
        :final url,
        :final containerGuid,
        :final essential,
        :final pinned,
        :final workspaceUuid,
      ):
        if (url.isEmpty || url == 'about:blank') {
          violations.add(
            BatchViolation(
              recordId: record.id,
              reason: 'tab url is empty or about:blank',
            ),
          );
        }
        checkContainerGuid(record.id, containerGuid);
        if (essential && !pinned) {
          violations.add(
            BatchViolation(
              recordId: record.id,
              reason: 'essential tab must be pinned',
            ),
          );
        }
        if (essential && workspaceUuid != null) {
          violations.add(
            BatchViolation(
              recordId: record.id,
              reason: 'essential tab must have a null workspaceUuid',
            ),
          );
        }

      case ZenFolderRecord(:final children):
        for (final childId in children) {
          checkChildId(record.id, childId);
        }

      case ZenSplitRecord(:final tabs):
        if (tabs.length < 2) {
          violations.add(
            BatchViolation(
              recordId: record.id,
              reason: 'split names fewer than two tabs',
            ),
          );
        }

      case ZenLayoutRecord(:final spaces, :final essentials):
        for (final spaceId in spaces) {
          checkChildId(record.id, spaceId);
        }
        for (final entry in essentials.entries) {
          if (entry.key != 'default' &&
              !resolvableContainerGuids.contains(entry.key)) {
            violations.add(
              BatchViolation(
                recordId: record.id,
                reason:
                    'essentials key "${entry.key}" is not a known '
                    'containerGuid',
              ),
            );
          }
          for (final tabId in entry.value) {
            checkChildId(record.id, tabId);
          }
        }
    }
  }

  return violations.isEmpty
      ? const BatchValidationOk()
      : BatchValidationRejected(violations);
}
