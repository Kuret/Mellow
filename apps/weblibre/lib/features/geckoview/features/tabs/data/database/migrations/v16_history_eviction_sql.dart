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

/// The `evictExcludedHistoryPages` / `reindexAfterExcludedHistoryEviction`
/// statements exactly as they read when `from15To16` shipped, pinned to the v16
/// shape of `history`/`tab`/`container` (`container.metadata` JSON flags).
///
/// The live named queries in definitions.drift have since moved to the
/// `container_local` table, which does not exist at v16; running them inside
/// the v15→v16 step would fail with "no such table" (see the note above the
/// live queries about migration SQL rotting). A migration runs against the
/// schema of its own version, so it must carry its own SQL.
const v16EvictExcludedHistoryPagesSql = r'''
  DELETE FROM history
  WHERE url_canonical IN (
      SELECT DISTINCT url_canonical(CAST(affected.url AS TEXT))
      FROM tab AS affected
      INNER JOIN container ON container.id = affected.container_id
      WHERE json_extract(container.metadata, '$.excludeFromHistory') = 1
        AND affected.url IS NOT NULL
        AND url_indexable(CAST(affected.url AS TEXT)) = 1
    )
    AND NOT EXISTS (
      SELECT 1
      FROM tab AS candidate
      WHERE candidate.url IS NOT NULL
        AND url_indexable(CAST(candidate.url AS TEXT)) = 1
        AND url_canonical(CAST(candidate.url AS TEXT)) = history.url_canonical
        AND (candidate.tab_mode != 1
             OR (SELECT value FROM local_index_setting WHERE "key" = 'index_private') = 1)
        AND NOT EXISTS (
          SELECT 1 FROM container
          WHERE container.id = candidate.container_id
            AND (json_extract(container.metadata, '$.excludeFromIndex') = 1
                 OR json_extract(container.metadata, '$.excludeFromHistory') = 1)
        )
    );''';

const v16ReindexAfterExcludedHistoryEvictionSql = r'''
  INSERT INTO history (
    url_canonical, url_host, url_path, title, is_probably_readerable,
    extracted_content_markdown, extracted_content_plain,
    full_content_markdown, full_content_plain,
    content_hash, observed_at, observed_count
  )
  SELECT
    url_canonical(CAST(candidate.url AS TEXT)),
    url_host(CAST(candidate.url AS TEXT)),
    url_path(CAST(candidate.url AS TEXT)),
    candidate.title,
    candidate.is_probably_readerable,
    candidate.extracted_content_markdown,
    candidate.extracted_content_plain,
    candidate.full_content_markdown,
    candidate.full_content_plain,
    candidate.content_hash,
    strftime('%s','now') * 1000,
    1
  FROM tab AS candidate
  -- Same gate as the trigger this was cloned from: with the local index off
  -- there is nothing to re-index, and inserting here would hand a user who
  -- turned indexing off a freshly populated `history` (and, via
  -- `history_after_insert`, `history_fts`).
  WHERE (SELECT value FROM local_index_setting WHERE "key" = 'enabled') = 1
    AND candidate.url IS NOT NULL
    AND url_indexable(CAST(candidate.url AS TEXT)) = 1
    AND url_canonical(CAST(candidate.url AS TEXT)) IN (
      SELECT DISTINCT url_canonical(CAST(affected.url AS TEXT))
      FROM tab AS affected
      INNER JOIN container ON container.id = affected.container_id
      WHERE json_extract(container.metadata, '$.excludeFromHistory') = 1
        AND affected.url IS NOT NULL
        AND url_indexable(CAST(affected.url AS TEXT)) = 1
    )
    AND (candidate.tab_mode != 1
         OR (SELECT value FROM local_index_setting WHERE "key" = 'index_private') = 1)
    AND NOT EXISTS (
      SELECT 1 FROM container
      WHERE container.id = candidate.container_id
        AND (json_extract(container.metadata, '$.excludeFromIndex') = 1
             OR json_extract(container.metadata, '$.excludeFromHistory') = 1)
    )
    AND NOT EXISTS (
      SELECT 1
      FROM tab AS newer
      WHERE newer.url IS NOT NULL
        AND url_indexable(CAST(newer.url AS TEXT)) = 1
        AND url_canonical(CAST(newer.url AS TEXT)) = url_canonical(CAST(candidate.url AS TEXT))
        AND (newer.tab_mode != 1
             OR (SELECT value FROM local_index_setting WHERE "key" = 'index_private') = 1)
        AND NOT EXISTS (
          SELECT 1 FROM container
          WHERE container.id = newer.container_id
            AND (json_extract(container.metadata, '$.excludeFromIndex') = 1
                 OR json_extract(container.metadata, '$.excludeFromHistory') = 1)
        )
        AND (
          newer.timestamp > candidate.timestamp
          OR (newer.timestamp = candidate.timestamp AND newer.rowid > candidate.rowid)
        )
    )
  ON CONFLICT(url_canonical) DO UPDATE SET
    title                       = COALESCE(excluded.title, history.title),
    is_probably_readerable      = excluded.is_probably_readerable,
    extracted_content_markdown  = excluded.extracted_content_markdown,
    extracted_content_plain     = excluded.extracted_content_plain,
    full_content_markdown       = excluded.full_content_markdown,
    full_content_plain          = excluded.full_content_plain,
    content_hash                = excluded.content_hash,
    observed_at                 = excluded.observed_at,
    observed_count              = history.observed_count + 1;''';
