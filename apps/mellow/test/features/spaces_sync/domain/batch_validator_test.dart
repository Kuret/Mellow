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
import 'package:mellow/features/spaces_sync/data/models/zen_records.dart';
import 'package:mellow/features/spaces_sync/domain/batch_validator.dart';

ZenTabRecord _tab({
  String tabId = 'tab-1',
  String url = 'https://example.com/',
  String? containerGuid,
  bool essential = false,
  bool pinned = false,
  String? workspaceUuid = '{space-1}',
}) => ZenTabRecord(
  tabId: tabId,
  url: url,
  title: 'Example',
  icon: '',
  containerGuid: containerGuid,
  essential: essential,
  pinned: pinned,
  workspaceUuid: workspaceUuid,
  folderId: null,
  staticLabel: null,
  hasStaticIcon: false,
  defaultContainer: false,
);

List<BatchViolation> _reject(BatchValidationResult result) {
  expect(result, isA<BatchValidationRejected>());
  return (result as BatchValidationRejected).violations;
}

void main() {
  group('a clean batch', () {
    test('is accepted', () {
      final result = validateOutgoingBatch(
        [
          ZenCleartext(
            id: 'tab-1',
            data: _tab(tabId: 'tab-1', containerGuid: 'guid-1'),
          ),
        ],
        knownIds: {},
        knownContainerGuids: {'guid-1'},
      );
      expect(result, isA<BatchValidationOk>());
    });

    test('ids/guids introduced within the same batch resolve', () {
      final result = validateOutgoingBatch(
        [
          ZenCleartext(
            id: 'guid-1',
            data: ZenContainerRecord(
              guid: 'guid-1',
              name: 'Work',
              icon: '',
              color: 'blue',
            ),
          ),
          ZenCleartext(
            id: 'space-1',
            data: ZenSpaceRecord(
              uuid: 'space-1',
              name: 'Personal',
              icon: null,
              theme: null,
              containerGuid: 'guid-1',
              children: ['tab-1'],
            ),
          ),
          ZenCleartext(
            id: 'tab-1',
            data: _tab(tabId: 'tab-1', containerGuid: 'guid-1'),
          ),
        ],
        knownIds: {},
        knownContainerGuids: {},
      );
      expect(result, isA<BatchValidationOk>());
    });
  });

  group('unresolved child ids', () {
    test('a space child id that resolves nowhere is a violation', () {
      final result = validateOutgoingBatch(
        [
          ZenCleartext(
            id: 'space-1',
            data: ZenSpaceRecord(
              uuid: 'space-1',
              name: 'Personal',
              icon: null,
              theme: null,
              containerGuid: null,
              children: ['missing-tab'],
            ),
          ),
        ],
        knownIds: {},
        knownContainerGuids: {},
      );
      final violations = _reject(result);
      expect(violations.single.recordId, 'space-1');
      expect(violations.single.reason, contains('missing-tab'));
    });

    test('a folder child id that resolves nowhere is a violation', () {
      final result = validateOutgoingBatch(
        [
          ZenCleartext(
            id: 'folder-1',
            data: ZenFolderRecord(
              folderId: 'folder-1',
              name: 'Research',
              icon: null,
              workspaceUuid: null,
              parentFolderId: null,
              live: null,
              children: ['missing-tab'],
            ),
          ),
        ],
        knownIds: {},
        knownContainerGuids: {},
      );
      expect(_reject(result), isNotEmpty);
    });

    test(
      'a layout spaces/essentials id that resolves nowhere is a violation',
      () {
        final result = validateOutgoingBatch(
          [
            ZenCleartext(
              id: 'layout',
              data: ZenLayoutRecord(
                spaces: ['missing-space'],
                essentials: {
                  'default': ['missing-tab'],
                },
              ),
            ),
          ],
          knownIds: {},
          knownContainerGuids: {},
        );
        final violations = _reject(result);
        expect(
          violations.any((v) => v.reason.contains('missing-space')),
          isTrue,
        );
        expect(violations.any((v) => v.reason.contains('missing-tab')), isTrue);
      },
    );

    test('a known id from a previous sync resolves', () {
      final result = validateOutgoingBatch(
        [
          ZenCleartext(
            id: 'space-1',
            data: ZenSpaceRecord(
              uuid: 'space-1',
              name: 'Personal',
              icon: null,
              theme: null,
              containerGuid: null,
              children: ['already-known-tab'],
            ),
          ),
        ],
        knownIds: {'already-known-tab'},
        knownContainerGuids: {},
      );
      expect(result, isA<BatchValidationOk>());
    });
  });

  group('unresolved container guids', () {
    test('a tab containerGuid that does not exist is a violation', () {
      final result = validateOutgoingBatch(
        [
          ZenCleartext(
            id: 'tab-1',
            data: _tab(tabId: 'tab-1', containerGuid: 'no-such-guid'),
          ),
        ],
        knownIds: {},
        knownContainerGuids: {},
      );
      final violations = _reject(result);
      expect(violations.single.reason, contains('no-such-guid'));
    });

    test('a space containerGuid that does not exist is a violation', () {
      final result = validateOutgoingBatch(
        [
          ZenCleartext(
            id: 'space-1',
            data: ZenSpaceRecord(
              uuid: 'space-1',
              name: 'Personal',
              icon: null,
              theme: null,
              containerGuid: 'no-such-guid',
              children: const [],
            ),
          ),
        ],
        knownIds: {},
        knownContainerGuids: {},
      );
      expect(_reject(result), isNotEmpty);
    });

    test('a layout essentials key other than "default" must be known', () {
      final result = validateOutgoingBatch(
        [
          ZenCleartext(
            id: 'layout',
            data: ZenLayoutRecord(
              spaces: const [],
              essentials: {'no-such-guid': const []},
            ),
          ),
        ],
        knownIds: {},
        knownContainerGuids: {},
      );
      expect(_reject(result), isNotEmpty);
    });

    test('"default" never needs to resolve as a containerGuid', () {
      final result = validateOutgoingBatch(
        [
          ZenCleartext(
            id: 'tab-1',
            data: _tab(
              tabId: 'tab-1',
              essential: true,
              pinned: true,
              workspaceUuid: null,
            ),
          ),
          ZenCleartext(
            id: 'layout',
            data: ZenLayoutRecord(
              spaces: const [],
              essentials: {
                'default': ['tab-1'],
              },
            ),
          ),
        ],
        knownIds: {},
        knownContainerGuids: {},
      );
      expect(result, isA<BatchValidationOk>());
    });
  });

  group('essential/pinned invariants', () {
    test('an essential tab with a non-null workspaceUuid is a violation', () {
      final result = validateOutgoingBatch(
        [
          ZenCleartext(
            id: 'tab-1',
            data: _tab(
              tabId: 'tab-1',
              essential: true,
              pinned: true,
              workspaceUuid: '{space-1}',
            ),
          ),
        ],
        knownIds: {},
        knownContainerGuids: {},
      );
      final violations = _reject(result);
      expect(violations.any((v) => v.reason.contains('workspaceUuid')), isTrue);
    });

    test('essential == true && pinned == false is a violation', () {
      final result = validateOutgoingBatch(
        [
          ZenCleartext(
            id: 'tab-1',
            data: _tab(
              tabId: 'tab-1',
              essential: true,
              pinned: false,
              workspaceUuid: null,
            ),
          ),
        ],
        knownIds: {},
        knownContainerGuids: {},
      );
      final violations = _reject(result);
      expect(violations.any((v) => v.reason.contains('pinned')), isTrue);
    });

    test('a valid essential tab (pinned, no workspace) is accepted', () {
      final result = validateOutgoingBatch(
        [
          ZenCleartext(
            id: 'tab-1',
            data: _tab(
              tabId: 'tab-1',
              essential: true,
              pinned: true,
              workspaceUuid: null,
            ),
          ),
        ],
        knownIds: {},
        knownContainerGuids: {},
      );
      expect(result, isA<BatchValidationOk>());
    });
  });

  group('tab url', () {
    test('an empty url is a violation', () {
      final result = validateOutgoingBatch(
        [
          ZenCleartext(
            id: 'tab-1',
            data: _tab(tabId: 'tab-1', url: ''),
          ),
        ],
        knownIds: {},
        knownContainerGuids: {},
      );
      expect(_reject(result), isNotEmpty);
    });

    test('about:blank is a violation', () {
      final result = validateOutgoingBatch(
        [
          ZenCleartext(
            id: 'tab-1',
            data: _tab(tabId: 'tab-1', url: 'about:blank'),
          ),
        ],
        knownIds: {},
        knownContainerGuids: {},
      );
      expect(_reject(result), isNotEmpty);
    });
  });

  group('split membership', () {
    test('a split with fewer than two tabs is a violation', () {
      final result = validateOutgoingBatch(
        [
          ZenCleartext(
            id: 'split-1',
            data: ZenSplitRecord(
              splitId: 'split-1',
              gridType: 'grid',
              pinned: false,
              tabs: const ['only-one'],
              workspaceUuid: null,
              folderId: null,
            ),
          ),
        ],
        knownIds: {'only-one'},
        knownContainerGuids: {},
      );
      expect(_reject(result), isNotEmpty);
    });

    test('a split with two or more tabs is accepted', () {
      final result = validateOutgoingBatch(
        [
          ZenCleartext(
            id: 'split-1',
            data: ZenSplitRecord(
              splitId: 'split-1',
              gridType: 'grid',
              pinned: false,
              tabs: const ['tab-a', 'tab-b'],
              workspaceUuid: null,
              folderId: null,
            ),
          ),
        ],
        knownIds: {'tab-a', 'tab-b'},
        knownContainerGuids: {},
      );
      expect(result, isA<BatchValidationOk>());
    });
  });

  group('recordId mismatch', () {
    test(
      'a cleartext id that does not match the data recordId is a violation',
      () {
        final result = validateOutgoingBatch(
          [
            ZenCleartext(
              id: 'wrong-id',
              data: _tab(tabId: 'tab-1'),
            ),
          ],
          knownIds: {},
          knownContainerGuids: {},
        );
        final violations = _reject(result);
        expect(violations.single.recordId, 'wrong-id');
        expect(violations.single.reason, contains('tab-1'));
      },
    );
  });
}
