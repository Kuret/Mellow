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

import 'package:flutter_test/flutter_test.dart';
import 'package:weblibre/features/spaces_sync/data/models/zen_records.dart';

/// One fixture per record kind, each realistic and each round-trip-testable:
/// re-encoding a decoded record must produce byte-identical canonical JSON
/// to the source (PLAN §8.6 item 1, the round-trip fidelity gate).
final fixtures = <Map<String, Object?>>[
  {
    'id': 'guid-1',
    'kind': 'container',
    'data': {
      'guid': 'guid-1',
      'name': 'Work',
      'icon': 'briefcase',
      'color': 'blue',
    },
  },
  {
    'id': '{11111111-1111-4111-8111-111111111111}',
    'kind': 'space',
    'data': {
      'uuid': '{11111111-1111-4111-8111-111111111111}',
      'name': 'Personal',
      'icon': null,
      'theme': {
        'accent': '#ff4bda',
        'gradient': [1, 2, 3],
        'opacity': 0.8,
      },
      'containerGuid': null,
      'children': ['1757600000000-42', 'folder-1'],
    },
  },
  {
    'id': '1757600000042-7',
    'kind': 'tab',
    'data': {
      'tabId': '1757600000042-7',
      'url': 'https://example.com/',
      'title': 'Example',
      'icon': '',
      'containerGuid': null,
      'essential': true,
      'pinned': true,
      'workspaceUuid': null,
      'folderId': null,
      'staticLabel': null,
      'hasStaticIcon': false,
      'defaultContainer': false,
    },
  },
  {
    'id': 'folder-1',
    'kind': 'folder',
    'data': {
      'folderId': 'folder-1',
      'name': 'Research',
      'icon': null,
      'workspaceUuid': '{11111111-1111-4111-8111-111111111111}',
      'parentFolderId': null,
      'live': {
        'provider': 'rss',
        'config': {'url': 'https://example.com/feed', 'refreshMinutes': 30},
      },
      'children': ['1757600000099-3'],
    },
  },
  {
    'id': 'split-1',
    'kind': 'split',
    'data': {
      'splitId': 'split-1',
      'gridType': 'grid',
      'pinned': false,
      'tabs': ['tab-a', 'tab-b'],
      'workspaceUuid': '{11111111-1111-4111-8111-111111111111}',
      'folderId': null,
    },
  },
  {
    'id': 'layout',
    'kind': 'layout',
    'data': {
      'spaces': ['{11111111-1111-4111-8111-111111111111}'],
      'essentials': {
        'default': ['1757600000042-7'],
        'guid-1': ['tab-c'],
      },
    },
  },
];

void main() {
  group('ZenRecordCodec.decode round-trip', () {
    for (final fixture in fixtures) {
      final kind = fixture['kind']! as String;
      test('$kind decodes and re-encodes byte-identically', () {
        final incoming = ZenRecordCodec.decode(fixture);
        expect(incoming, isA<ZenIncomingRecord>());
        final cleartext = (incoming as ZenIncomingRecord).cleartext;

        expect(cleartext.id, fixture['id']);
        expect(cleartext.kind, kind);
        expect(cleartext.data.recordId, fixture['id']);

        expect(canonicalJson(cleartext.toJson()), canonicalJson(fixture));
      });
    }
  });

  group('canonicalJson', () {
    test('sorts keys recursively', () {
      final a = canonicalJson({
        'b': 1,
        'a': {'z': 1, 'y': 2},
      });
      final b = jsonEncode({
        'a': {'y': 2, 'z': 1},
        'b': 1,
      });
      expect(a, b);
    });

    test('is stable regardless of source map key order', () {
      final data1 = {'name': 'Work', 'guid': 'g1', 'icon': 'x', 'color': 'y'};
      final data2 = {'color': 'y', 'icon': 'x', 'guid': 'g1', 'name': 'Work'};
      expect(canonicalJson(data1), canonicalJson(data2));
    });
  });

  group('recordDigest', () {
    test('is stable regardless of input map key order', () {
      final data1 = {'guid': 'g1', 'name': 'Work', 'icon': 'x', 'color': 'y'};
      final data2 = {'name': 'Work', 'color': 'y', 'guid': 'g1', 'icon': 'x'};
      expect(
        recordDigest('container', data1),
        recordDigest('container', data2),
      );
    });

    test('changes when content changes', () {
      final data1 = {'guid': 'g1', 'name': 'Work', 'icon': 'x', 'color': 'y'};
      final data2 = {
        'guid': 'g1',
        'name': 'Personal',
        'icon': 'x',
        'color': 'y',
      };
      expect(
        recordDigest('container', data1),
        isNot(recordDigest('container', data2)),
      );
    });

    test('is a base64 SHA-256 (44 chars, padded)', () {
      final digest = recordDigest('container', {
        'guid': 'g1',
        'name': 'Work',
        'icon': 'x',
        'color': 'y',
      });
      expect(digest, hasLength(44));
      expect(digest, endsWith('='));
    });
  });

  group('unknown kinds', () {
    test('are preserved verbatim as ZenIncomingUnknownKind', () {
      final raw = <String, Object?>{
        'id': 'foreign-1',
        'kind': 'note',
        'data': {'text': 'not a kind we understand'},
      };
      final incoming = ZenRecordCodec.decode(raw);
      expect(incoming, isA<ZenIncomingUnknownKind>());
      final unknown = incoming as ZenIncomingUnknownKind;
      expect(unknown.id, 'foreign-1');
      expect(unknown.kind, 'note');
      expect(unknown.rawData, raw['data']);
    });
  });

  group('tombstones', () {
    test('decode to ZenIncomingTombstone regardless of kind', () {
      final incoming = ZenRecordCodec.decode({'id': 'tab-x', 'deleted': true});
      expect(incoming, isA<ZenIncomingTombstone>());
      expect((incoming as ZenIncomingTombstone).id, 'tab-x');
    });

    test('ZenTombstone encodes to {"id","deleted":true}', () {
      final tombstone = ZenTombstone(id: 'tab-x');
      expect(tombstone.toJson(), {'id': 'tab-x', 'deleted': true});
    });
  });
}
