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

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mellow/core/design/app_colors.dart';
import 'package:mellow/core/routing/routes.dart';
import 'package:mellow/features/geckoview/domain/controllers/bottom_sheet.dart';
import 'package:mellow/features/geckoview/domain/entities/tab_container_selection.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_session.dart';
import 'package:mellow/features/geckoview/domain/providers/tab_state.dart';
import 'package:mellow/features/geckoview/domain/repositories/tab.dart';
import 'package:mellow/features/geckoview/features/browser/domain/providers.dart';
import 'package:mellow/features/geckoview/features/find_in_page/presentation/controllers/find_in_page.dart';
import 'package:mellow/features/geckoview/features/search/domain/entities/search_presentation.dart';
import 'package:mellow/features/geckoview/features/search/domain/providers/search_autofocus.dart';
import 'package:mellow/features/geckoview/features/search/domain/providers/search_section_display.dart';
import 'package:mellow/features/geckoview/features/search/presentation/widgets/animated_tab_type_switcher.dart';
import 'package:mellow/features/geckoview/features/search/presentation/widgets/clipboard_fill.dart';
import 'package:mellow/features/geckoview/features/search/presentation/widgets/empty_state/recent_searches_section.dart';
import 'package:mellow/features/geckoview/features/search/presentation/widgets/search_field.dart';
import 'package:mellow/features/geckoview/features/search/presentation/widgets/search_modules/combined_history_suggestions.dart';
import 'package:mellow/features/geckoview/features/search/presentation/widgets/search_modules/search_term_suggestions_section.dart';
import 'package:mellow/features/geckoview/features/search/presentation/widgets/search_panel.dart';
import 'package:mellow/features/geckoview/features/search/presentation/widgets/search_section_scope.dart';
import 'package:mellow/features/geckoview/features/tabs/data/entities/tab_mode.dart';
import 'package:mellow/features/geckoview/features/tabs/domain/providers/selected_container.dart';
import 'package:mellow/features/geckoview/features/tabs/presentation/widgets/compact_container_selector.dart';
import 'package:mellow/features/search/domain/entities/search_provider.dart';
import 'package:mellow/features/search/domain/providers/search_provider.dart';
import 'package:mellow/features/search/domain/repositories/search_history.dart';
import 'package:mellow/features/search/domain/services/search_provider_match.dart';
import 'package:mellow/features/user/domain/repositories/general_settings.dart';
import 'package:mellow/presentation/hooks/on_listenable_change_selector.dart';
import 'package:mellow/presentation/hooks/sampled_value_notifier.dart';
import 'package:mellow/utils/input_classification.dart';
import 'package:mellow/utils/text_field_line_count.dart';
import 'package:mellow/utils/ui_helper.dart' as ui_helper;

class SearchScreen extends HookConsumerWidget {
  final String? initialSearchText;
  final TabType tabType;
  final bool launchedFromIntent;
  final bool autoSubmitSearch;

  /// When provided, URLs will be loaded into this existing tab.
  /// When null, a new tab will be created.
  final String? tabId;

  /// Whether this is a page of its own or a card floating over the browser.
  /// The content is identical either way; only the chrome and the sizing
  /// differ. See [SearchPresentation].
  final SearchPresentation presentation;

  /// Height budget for [SearchPresentation.panel], normally supplied by
  /// [SearchPanel] from the viewport. Ignored when full screen.
  final double? panelMaxHeight;

  /// Height budget for [SearchPresentation.panel] once a web search has been
  /// dispatched and the card is showing results rather than suggestions.
  final double? panelExpandedMaxHeight;

  const SearchScreen({
    super.key,
    required this.initialSearchText,
    required this.tabType,
    this.launchedFromIntent = false,
    this.autoSubmitSearch = false,
    this.tabId,
    this.presentation = SearchPresentation.fullScreen,
    this.panelMaxHeight,
    this.panelExpandedMaxHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = AppColors.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final settings = ref.watch(generalSettingsWithDefaultsProvider);

    final selectedTabType = useState(tabType);

    final selectedContainer = ref.watch(
      selectedContainerDataProvider.select((value) => value.value),
    );

    // When editing an existing tab, get its state
    // If tab no longer exists (null), fall back to new tab mode
    final existingTabState = tabId != null
        ? ref.watch(tabStateProvider(tabId))
        : null;

    // Determine if we're in edit mode (tabId provided AND tab still exists)
    final isEditMode = tabId != null && existingTabState != null;

    final effectiveTabMode = isEditMode
        ? existingTabState.tabMode
        : switch (selectedTabType.value) {
            TabType.regular => TabMode.regular,
            TabType.private => TabMode.private,
          };

    final privateTabMode = effectiveTabMode is PrivateTabMode;

    final searchTextController = useTextEditingController(
      text: initialSearchText,
    );
    final sampledSearchText = useSampledValueNotifier(
      source: searchTextController,
      sampleDuration: const Duration(milliseconds: 150),
    );
    final hasUserProvidedInput = useState(
      initialSearchText?.isNotEmpty == true,
    );

    // Track if we started with a URL (edit mode) to show empty state initially
    final startedWithUrl = useMemoized(() {
      if (initialSearchText == null || initialSearchText!.isEmpty) return false;
      return classifyAddressBarInput(initialSearchText!)
          is NavigateInputClassification;
    });
    final hasUserModifiedInput = useState(false);
    final isUrlInput = useState(false);

    // Holds the original URL when reverse matching has swapped the
    // address-bar text for an extracted query. First tap of the clear button
    // restores this URL; a subsequent tap clears the field normally.
    final revertUrl = useState<String?>(null);
    final reverseMatchedQuery = useState<String?>(null);

    useOnListenableChangeSelector(
      searchTextController,
      () => searchTextController.text,
      () {
        final text = searchTextController.text;
        hasUserProvidedInput.value = text.isNotEmpty;

        if (startedWithUrl) {
          hasUserModifiedInput.value = text != initialSearchText;
        }
        isUrlInput.value =
            text.isNotEmpty &&
            classifyAddressBarInput(text) is NavigateInputClassification;
      },
    );

    final showNoInputSections =
        (startedWithUrl && !hasUserModifiedInput.value) ||
        (!hasUserProvidedInput.value && searchTextController.text.isEmpty);

    final searchFocusNode = useFocusNode();
    final pauseTime = useRef<DateTime?>(null);
    final textFieldKey = useMemoized(() => GlobalKey());
    final preferredHeight = useState<double>(kToolbarHeight);

    useOnListenableChangeSelector(
      searchFocusNode,
      () => searchFocusNode.hasFocus,
      () {
        if (searchFocusNode.hasFocus && isEditMode) {
          searchTextController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: searchTextController.text.length,
          );
        }
      },
    );

    useEffect(() {
      if (isEditMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          searchTextController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: searchTextController.text.length,
          );
        });
      }
      return null;
    }, []);

    // Try to recognise the current URL as a search we know how to run. If a
    // provider matches, swap the URL for the query that produced it and
    // pre-select that provider, so the user refines the search instead of
    // editing a raw results URL.
    useEffect(() {
      if (!startedWithUrl || initialSearchText == null) return null;
      final uri = Uri.tryParse(initialSearchText!);
      if (uri == null) return null;

      final match = matchSearchUrl(
        uri,
        providers: ref.read(allSearchProvidersProvider),
      );
      if (match == null) return null;

      // Deferred: the effect runs inside the build pass that mounted this
      // screen, and the selection providers must not be written to from there.
      unawaited(
        Future.microtask(() {
          if (!context.mounted) return;
          // Bail out if the user started editing before the frame settled.
          if (searchTextController.text != initialSearchText) return;

          revertUrl.value = initialSearchText;
          reverseMatchedQuery.value = match.searchTerms;
          searchTextController.value = TextEditingValue(
            text: match.searchTerms,
            selection: TextSelection(
              baseOffset: 0,
              extentOffset: match.searchTerms.length,
            ),
          );
          // Mutual exclusion: clear any site-scoped selection so the global
          // auto-match isn't hidden behind a stale site choice (mirrors the
          // SearchProviderChips selection logic).
          final tabHost = existingTabState?.url.host;
          if (tabHost != null && tabHost.isNotEmpty) {
            ref
                .read(selectedSearchProviderProvider(domain: tabHost).notifier)
                .clear();
          }
          ref
              .read(selectedSearchProviderProvider().notifier)
              .select(match.provider);
        }),
      );

      return null;
    }, []);

    //Request initial focus in a way our useOnListenableChangeSelector is triggered
    useEffect(() {
      if (ref.read(searchAutofocusSuppressionProvider)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(searchAutofocusSuppressionProvider.notifier).clear();
        });

        return null;
      }

      //Wait for first frame then request focus
      unawaited(
        Future.delayed(const Duration(milliseconds: 1000 ~/ 60)).whenComplete(
          () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              searchFocusNode.requestFocus();
            });
          },
        ),
      );

      return null;
    }, []);

    Future<void> measureHeightWithRetry() async {
      const delays = [25, 50, 75, 100];

      for (final delay in delays) {
        await Future.delayed(Duration(milliseconds: delay));
        final measuredHeight = getTextFieldHeight(textFieldKey);

        if (measuredHeight != null) {
          // Add 2px to account for SearchField container border
          preferredHeight.value = measuredHeight + 2;
          return;
        }
      }
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        measureHeightWithRetry(); // ignore: discarded_futures
      });

      return null;
    }, [textFieldKey, isEditMode]);

    useOnListenableChangeSelector(
      isEditMode ? searchTextController : null,
      () => searchTextController.text,
      () {
        measureHeightWithRetry(); // ignore: discarded_futures
      },
    );

    useOnAppLifecycleStateChange((previous, current) {
      switch (current) {
        case AppLifecycleState.hidden:
        case AppLifecycleState.paused:
          //Fixes issue with disappearing keyboard after resume (even we request focus)
          searchFocusNode.unfocus();
          pauseTime.value ??= DateTime.now();
        case AppLifecycleState.inactive:
        case AppLifecycleState.detached:
          // Transient focus loss (IME input-method picker via long-press
          // spacebar, notification shade, split-screen) reports `inactive`
          // while the field is still visible. Unfocusing here would tear down
          // the input connection and dismiss the keyboard/picker, so leave
          // focus untouched and only react to genuine backgrounding above.
          break;
        case AppLifecycleState.resumed:
          if (pauseTime.value == null ||
              DateTime.now().difference(pauseTime.value!) <
                  const Duration(minutes: 1)) {
            pauseTime.value = null;
            break;
          }

          pauseTime.value = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            searchFocusNode.requestFocus();
          });
      }
    });

    final defaultSearchProvider = ref.watch(defaultSearchProviderProvider);

    // Watch both selection providers - only one should be set at a time
    // due to mutual exclusion in SearchProviderChips
    final siteSelectedProvider = isEditMode
        ? ref.watch(
            selectedSearchProviderProvider(domain: existingTabState.url.host),
          )
        : null;
    final globalSelectedProvider = ref.watch(selectedSearchProviderProvider());

    // The active selection is whichever one is set (site takes priority if both somehow set)
    final selectedProvider = siteSelectedProvider ?? globalSelectedProvider;

    final activeProvider = selectedProvider ?? defaultSearchProvider;

    // The user named a provider for this search instead of falling back to the
    // default. That drives the field's provider icon, and it also settles what
    // enter means: search with that provider, not open the completed URL.
    final showProviderIcon = selectedProvider != null;

    // What the rest of the modules should search for — the field's text as
    // typed. Only the text matters downstream; selection and composing belong
    // to the field the user is actually editing.
    final sampledQueryText = useValueNotifier(sampledSearchText.value);
    useEffect(() {
      void sync() {
        sampledQueryText.value = sampledSearchText.value;
      }

      sync();
      sampledSearchText.addListener(sync);
      return () => sampledSearchText.removeListener(sync);
    }, [sampledSearchText, sampledQueryText]);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        measureHeightWithRetry(); // ignore: discarded_futures
      });

      return null;
    }, [showProviderIcon]);

    Future<void> openUriInTab(Uri uri, {String? findInPageQuery}) async {
      final String targetTabId;
      if (isEditMode) {
        targetTabId = tabId!;
        await ref
            .read(tabSessionProvider(tabId: targetTabId).notifier)
            .loadUrl(url: uri);
      } else {
        targetTabId = await ref
            .read(tabRepositoryProvider.notifier)
            .addTab(
              url: uri,
              tabMode: effectiveTabMode,
              launchedFromIntent: launchedFromIntent,
              selectTab: true,
              containerSelection: selectedContainer == null
                  ? const TabContainerSelection.unassigned()
                  : TabContainerSelection.specific(selectedContainer),
            );
      }

      if (findInPageQuery != null && findInPageQuery.isNotEmpty) {
        await ref
            .read(findInPageControllerProvider(targetTabId).notifier)
            .findAll(text: findInPageQuery);
      }

      if (context.mounted) {
        ref.read(bottomSheetControllerProvider.notifier).requestDismiss();
        const BrowserRoute().go(context);
      }
    }

    /// Records the search and returns the URI that runs it.
    Future<Uri> resolveSearchUri(SearchProvider provider, String query) async {
      if (!privateTabMode) {
        await ref
            .read(searchHistoryRepositoryProvider.notifier)
            .addEntry(query, maxEntryCount: kMaxSearchHistoryEntries);
      }

      return provider.searchUrl(query);
    }

    Future<void> submitSearch(String query) async {
      if (formKey.currentState?.validate() != true) {
        return;
      }

      await openUriInTab(await resolveSearchUri(activeProvider, query));
    }

    final scrollController = useScrollController();

    final isPanel = presentation == SearchPresentation.panel;

    // The card shrink-wraps its content, so it needs an upper bound to stop it
    // from growing into a full-screen page by another name.
    final panelHeightBudget =
        panelMaxHeight ??
        (kSearchPanelListMaxHeight + kSearchPanelFieldAllowance);

    final slivers = <Widget>[
      SliverAppBar(
        // A floating header needs a viewport that scrolls past its
        // content; the shrink-wrapped panel often has none.
        floating: !isPanel,
        pinned: true,
        automaticallyImplyLeading: false,
        // `primary` (default true) pads for the status bar unconditionally,
        // on top of whatever `toolbarHeight`/`title` need. The full-screen
        // route sits under a `SafeArea` that already zeroes that padding out
        // for it, but the floating card has no such wrapper and already
        // clears the status bar via its own positioning — so left at the
        // default this reserves a second, empty status-bar-high gap above
        // the field.
        primary: !isPanel,
        backgroundColor: isPanel
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surface,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        // Collapse the toolbar in edit mode: there is no tab-type switcher to
        // show there.
        toolbarHeight: isEditMode ? 0 : kToolbarHeight,
        titleSpacing: 0.0,
        title: isEditMode
            ? null
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Builder(
                  builder: (context) {
                    final tabTypeSwitcher = Focus(
                      canRequestFocus: false,
                      child: AnimatedTabTypeSwitcher(
                        selected: selectedTabType.value,
                        onChanged: (value) {
                          selectedTabType.value = value;
                          // Restore focus to search field after segment change
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            searchFocusNode.requestFocus();
                          });
                        },
                        selectedBackgroundColor: switch (selectedTabType
                            .value) {
                          TabType.regular => null,
                          TabType.private => appColors.privateSelectionOverlay,
                        },
                      ),
                    );

                    if (!settings.showContainerUi) {
                      return Center(
                        child: Transform.scale(
                          scale: 1.08,
                          child: tabTypeSwitcher,
                        ),
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: tabTypeSwitcher,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: CompactContainerSelector(
                              selectedContainer: selectedContainer,
                              emphasizeSelection: false,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(preferredHeight.value),
          child: SearchField(
            textFieldKey: textFieldKey,
            showProviderIcon: showProviderIcon,
            explicitProviderSelected: showProviderIcon,
            textEditingController: searchTextController,
            focusNode: searchFocusNode,
            maxLines: isEditMode ? 3 : 1,
            privateMode: privateTabMode,
            label: const Text('Search or enter URL'),
            unfocusOnTapOutside: false,
            onClearPressed: () {
              final url = revertUrl.value;
              if (url != null &&
                  searchTextController.text == reverseMatchedQuery.value) {
                // First press after a reverse-match swap: restore the
                // original URL and drop the auto-selected provider. The
                // user can press again to actually clear.
                searchTextController.value = TextEditingValue(
                  text: url,
                  selection: TextSelection(
                    baseOffset: 0,
                    extentOffset: url.length,
                  ),
                );
                revertUrl.value = null;
                reverseMatchedQuery.value = null;
                ref.read(selectedSearchProviderProvider().notifier).clear();
              } else {
                revertUrl.value = null;
                reverseMatchedQuery.value = null;
                searchTextController.clear();
              }
            },
            onSubmitted: (value) async {
              if (value.isEmpty) return;

              switch (classifyAddressBarInput(value)) {
                case NavigateInputClassification(:final uri):
                  await openUriInTab(uri);
                case SearchInputClassification(:final query):
                  // Read from both overrides - use site if set, otherwise
                  // global, otherwise the standing default.
                  final siteProvider = isEditMode
                      ? ref.read(
                          selectedSearchProviderProvider(
                            domain: existingTabState.url.host,
                          ),
                        )
                      : null;
                  final globalProvider = ref.read(
                    selectedSearchProviderProvider(),
                  );
                  // Annotated: the standing default always answers, so the
                  // chain cannot come up empty even though both overrides can.
                  final SearchProvider provider =
                      siteProvider ??
                      globalProvider ??
                      ref.read(defaultSearchProviderProvider);

                  await openUriInTab(await resolveSearchUri(provider, query));
                case InvalidInputClassification():
                  if (context.mounted) {
                    ui_helper.showErrorMessage(context, 'Invalid address');
                  }
              }
            },
            activeProvider: activeProvider,
            showSuggestions: true,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: ClipboardFillLink(controller: searchTextController),
      ),
      // A fixed pair, in this order: what the autocomplete provider thinks you
      // are typing, then where you have already been.
      //
      // The panel reads as a spotlight — field, then results — so it never
      // shows the recent-searches empty state: with nothing typed these two
      // sections have nothing to suggest either and hide themselves rather
      // than leave empty headers between the field and the clipboard-fill
      // row. The full-screen route keeps its original empty state, recent
      // searches included.
      if (isPanel) ...[
        SearchTermSuggestionsSection(
          searchTextController: searchTextController,
          submitSearch: submitSearch,
          hideWhenEmpty: true,
        ),
        CombinedHistorySuggestions(
          searchTextListenable: sampledQueryText,
          onUriSelected: openUriInTab,
          hideWhenEmpty: true,
        ),
      ] else if (showNoInputSections)
        RecentSearchesSection(
          searchTextController: searchTextController,
          submitSearch: submitSearch,
        )
      else ...[
        SearchTermSuggestionsSection(
          searchTextController: searchTextController,
          submitSearch: submitSearch,
        ),
        CombinedHistorySuggestions(
          searchTextListenable: sampledQueryText,
          onUriSelected: openUriInTab,
        ),
      ],
      // Keeps the last row clear of the card's rounded bottom edge.
      if (isPanel) const SliverToBoxAdapter(child: SizedBox(height: 8)),
    ];

    final content = Form(
      key: formKey,
      child: SearchSectionScope(
        host: SearchSectionHost.panel,
        pinnedHeaderBackgroundColor: isPanel
            ? colorScheme.surfaceContainerHigh
            : Theme.of(context).canvasColor,
        child: isPanel
            ? SearchPanelBody(
                maxHeight: panelHeightBudget,
                controller: scrollController,
                slivers: slivers,
              )
            : CustomScrollView(controller: scrollController, slivers: slivers),
      ),
    );

    return isPanel ? content : Scaffold(body: SafeArea(child: content));
  }
}
