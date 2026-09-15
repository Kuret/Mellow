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
import 'package:mellow/data/models/web_page_info.dart';
import 'package:mellow/domain/services/generic_website.dart';
import 'package:mellow/extensions/ref_cache.dart';
import 'package:mellow/extensions/uri.dart';
import 'package:mellow/features/geckoview/domain/entities/states/tab.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_state.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'website_title.g.dart';

@Riverpod()
class CompletePageInfo extends _$CompletePageInfo {
  @override
  AsyncValue<WebPageInfo> build(TabState cached) {
    ref.cacheFor(const Duration(minutes: 2));

    if (cached.isPageInfoComplete || !cached.url.isHttpOrHttps) {
      return AsyncData(cached);
    }

    ref.listen(
      fireImmediately: true,
      tabStateProvider(cached.id).select((value) => value?.title),
      (previous, next) {
        if (next != null) {
          final current = stateOrNull?.value ?? cached;
          state = AsyncData(current.copyWith.title(next));
        }
      },
    );

    ref.listen(
      fireImmediately: true,
      tabStateProvider(cached.id).select((value) => value?.favicon),
      (previous, next) {
        if (next != null) {
          final current = stateOrNull?.value ?? cached;
          state = AsyncData(current.copyWith.favicon(next));
        }
      },
    );

    return AsyncData(cached);
  }
}

@Riverpod()
Future<WebPageInfo> pageInfo(
  Ref ref,
  Uri url, {
  required bool isImageRequest,
}) async {
  final link = ref.cacheFor(const Duration(minutes: 2));

  final result = await ref
      .watch(genericWebsiteServiceProvider.notifier)
      .fetchPageInfo(url: url, isImageRequest: isImageRequest);

  if (!result.isSuccess) {
    link.close();
  }

  return result.value;
}
