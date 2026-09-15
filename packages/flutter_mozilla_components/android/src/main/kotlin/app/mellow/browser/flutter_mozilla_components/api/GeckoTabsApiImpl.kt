/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package app.mellow.browser.flutter_mozilla_components.api

import app.mellow.browser.flutter_mozilla_components.history.HistoryExclusions
import app.mellow.browser.flutter_mozilla_components.pigeons.AddTabParams
import app.mellow.browser.flutter_mozilla_components.pigeons.GeckoTabsApi
import app.mellow.browser.flutter_mozilla_components.pigeons.HistoryMetadataKey as PigeonHistoryMetadataKey
import app.mellow.browser.flutter_mozilla_components.pigeons.LoadUrlFlagsValue
import app.mellow.browser.flutter_mozilla_components.pigeons.RestoreLocation as PigeonRestoreLocation
import app.mellow.browser.flutter_mozilla_components.pigeons.RecoverableTab as PigeonRecoverableTab
import app.mellow.browser.flutter_mozilla_components.pigeons.SourceValue
import app.mellow.browser.flutter_mozilla_components.pigeons.WebExtensionActionType
import app.mellow.browser.flutter_mozilla_components.pigeons.WebExtensionData
import app.mellow.browser.flutter_mozilla_components.GlobalComponents
import app.mellow.browser.flutter_mozilla_components.ext.EventSequence
import app.mellow.browser.flutter_mozilla_components.ext.toWebPBytes
import app.mellow.browser.flutter_mozilla_components.pigeons.FindResultState
import app.mellow.browser.flutter_mozilla_components.pigeons.GeckoStateEvents
import app.mellow.browser.flutter_mozilla_components.pigeons.HistoryItem
import app.mellow.browser.flutter_mozilla_components.pigeons.HistoryState
import app.mellow.browser.flutter_mozilla_components.pigeons.RestoreLocation
import app.mellow.browser.flutter_mozilla_components.pigeons.SecurityInfoState
import app.mellow.browser.flutter_mozilla_components.pigeons.TabContentState
import java.util.UUID
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import mozilla.components.browser.icons.BrowserIcons
import mozilla.components.browser.icons.IconRequest
import mozilla.components.browser.session.storage.RecoverableBrowserState
import mozilla.components.browser.state.action.EngineAction
import mozilla.components.browser.state.action.TabListAction
import mozilla.components.browser.state.selector.findTab
import mozilla.components.browser.state.state.BrowserState
import mozilla.components.browser.state.state.LastMediaAccessState
import mozilla.components.browser.state.state.SessionState
import mozilla.components.browser.state.state.createTab
import mozilla.components.browser.state.state.recover.RecoverableTab
import mozilla.components.browser.state.state.recover.TabState
import mozilla.components.browser.thumbnails.storage.ThumbnailStorage
import mozilla.components.concept.base.images.ImageLoadRequest
import mozilla.components.concept.storage.HistoryMetadataKey
import mozilla.components.feature.tabs.TabsUseCases
import org.json.JSONObject
import org.mozilla.gecko.util.ThreadUtils.runOnUiThread
import mozilla.components.feature.addons.logger
import mozilla.components.concept.engine.EngineSession

class GeckoTabsApiImpl : GeckoTabsApi {
    companion object {
        private const val TAG = "GeckoTabsApi"
        private val coroutineScope = CoroutineScope(Dispatchers.Default)
    }

    private val components by lazy {
        requireNotNull(GlobalComponents.components) { "Components not initialized" }
    }

    private fun restoreSource(source: SourceValue): SessionState.Source {
        return SessionState.Source.restore(
            source.id.toInt(),
            source.caller?.packageId,
            source.caller?.category?.value?.toInt()
        )
    }

    private fun mapTab(tab: PigeonRecoverableTab): RecoverableTab {
        return RecoverableTab(
            engineSessionState = tab.engineSessionStateJson?.let { json ->
                components.core.engine.createSessionState(JSONObject(json))
            },
            state = TabState(
                id = tab.state.id,
                url = tab.state.url,
                parentId = tab.state.parentId,
                title = tab.state.title,
                searchTerm = tab.state.searchTerm,
                contextId = tab.state.contextId,
                lastAccess = tab.state.lastAccess,
                createdAt = tab.state.createdAt,
                lastMediaAccessState = LastMediaAccessState(
                    lastMediaUrl = tab.state.lastMediaAccessState.lastMediaUrl,
                    lastMediaAccess = tab.state.lastMediaAccessState.lastMediaAccess,
                    mediaSessionActive = tab.state.lastMediaAccessState.mediaSessionActive
                ),
                private = tab.state.private,
                historyMetadata = tab.state.historyMetadata?.let { metadata ->
                    HistoryMetadataKey(
                        url = metadata.url,
                        searchTerm = metadata.searchTerm,
                        referrerUrl = metadata.referrerUrl
                    )
                },
                source = restoreSource(tab.state.source),
                index = tab.state.index.toInt(),
                hasFormData = tab.state.hasFormData
            )
        )
    }

    private fun mapRestoreLocation(location: PigeonRestoreLocation): TabListAction.RestoreAction.RestoreLocation {
        return when (location) {
            RestoreLocation.BEGINNING -> TabListAction.RestoreAction.RestoreLocation.BEGINNING
            RestoreLocation.END -> TabListAction.RestoreAction.RestoreLocation.END
            RestoreLocation.AT_INDEX -> TabListAction.RestoreAction.RestoreLocation.AT_INDEX
        }
    }

    private suspend fun handleIconChange(tab: SessionState) {
        try {
            val iconBytes: ByteArray?
            if (tab.content.icon != null) {
                iconBytes = tab.content.icon?.toWebPBytes()
            } else {
                iconBytes = null
            }

            withContext(Dispatchers.Main) {
                components.flutterEvents.onIconChange(
                    EventSequence.next(),
                    tab.id,
                    iconBytes
                ) { }
            }
        } catch (e: Exception) {
            logger.error("$TAG: Failed to handle icon change for tab ${tab.id}", e)
        }
    }

    private suspend fun handleThumbnailChange(tab: SessionState) {
        try {
            val bitmap = components.core.thumbnailStorage.loadThumbnail(
                ImageLoadRequest(
                    id = tab.id,
                    size = 1024,
                    isPrivate = tab.content.private
                )
            ).await()

            bitmap?.let {
                val bytes = it.toWebPBytes()
                withContext(Dispatchers.Main) {
                    components.flutterEvents.onThumbnailChange(
                        EventSequence.next(),
                        tab.id,
                        bytes
                    ) { }
                }
            }
        } catch (e: Exception) {
            logger.error("$TAG: Failed to handle thumbnail change for tab ${tab.id}", e)
        }
    }

    override fun syncEvents(
        onSelectedTabChange: Boolean,
        onTabListChange: Boolean,
        onRestoreComplete: Boolean,
        onTabContentStateChange: Boolean,
        onIconChange: Boolean,
        onSecurityInfoStateChange: Boolean,
        onHistoryStateChange: Boolean,
        onFindResults: Boolean,
        onThumbnailChange: Boolean,
        onBrowserExtensionsChange: Boolean,
        onPageExtensionsChange: Boolean,
        onBrowserExtensionIcons: Boolean,
        onPageExtensionIcons: Boolean,
    ) {
        try {
            val tabs = components.core.store.state.tabs.map { it.copy() }
            val selectedTab = components.core.store.state.selectedTabId

            if (onSelectedTabChange) {
                components.flutterEvents.onSelectedTabChange(
                    EventSequence.next(),
                    selectedTab
                ) { }
            }

            if (onTabListChange) {
                components.flutterEvents.onTabListChange(
                    EventSequence.next(),
                    tabs.map { it.id }) { }
            }

            if (onRestoreComplete) {
                components.flutterEvents.onRestoreCompleteChange(
                    EventSequence.next(),
                    components.core.store.state.restoreComplete
                ) { }
            }

            tabs.forEach { tab ->
                if (onTabContentStateChange) {
                    components.flutterEvents.onTabContentStateChange(
                        EventSequence.next(),
                        TabContentState(
                            id = tab.id,
                            parentId = tab.parentId,
                            contextId = tab.contextId,
                            url = tab.content.url,
                            title = tab.content.title,
                            progress = tab.content.progress.toLong(),
                            isPrivate = tab.content.private,
                            isFullScreen = tab.content.fullScreen,
                            isLoading = tab.content.loading,
                            showToolbarAsExpanded = tab.content.showToolbarAsExpanded,
                        )
                    ) { }
                }

                if (onIconChange) {
                    coroutineScope.launch { handleIconChange(tab) }
                }

                if (onSecurityInfoStateChange) {
                    components.flutterEvents.onSecurityInfoStateChange(
                        EventSequence.next(),
                        tab.id,
                        SecurityInfoState(
                            tab.content.securityInfo.isSecure,
                            tab.content.securityInfo.host,
                            tab.content.securityInfo.issuer
                        )
                    ) { }
                }

                if (onHistoryStateChange) {
                    components.flutterEvents.onHistoryStateChange(
                        EventSequence.next(),
                        tab.id,
                        HistoryState(
                            items = tab.content.history.items.map { item ->
                                HistoryItem(url = item.uri, title = item.title)
                            },
                            currentIndex = tab.content.history.currentIndex.toLong(),
                            canGoBack = tab.content.canGoBack,
                            canGoForward = tab.content.canGoForward
                        )
                    ) { }
                }

                if (onFindResults) {
                    components.flutterEvents.onFindResults(
                        EventSequence.next(),
                        tab.id,
                        tab.content.findResults.map { result ->
                            FindResultState(
                                activeMatchOrdinal = result.activeMatchOrdinal.toLong(),
                                numberOfMatches = result.numberOfMatches.toLong(),
                                isDoneCounting = result.isDoneCounting
                            )
                        }
                    ) { }
                }

                if (onThumbnailChange) {
                    coroutineScope.launch { handleThumbnailChange(tab) }
                }
            }

            // Sync extension events
            if (onBrowserExtensionsChange || onPageExtensionsChange ||
                onBrowserExtensionIcons || onPageExtensionIcons) {
                syncExtensionEvents(
                    onBrowserExtensionsChange,
                    onPageExtensionsChange,
                    onBrowserExtensionIcons,
                    onPageExtensionIcons
                )
            }
        } catch (e: Exception) {
            logger.error("$TAG: Failed to sync events", e)
        }
    }

    private fun syncExtensionEvents(
        onBrowserExtensionsChange: Boolean,
        onPageExtensionsChange: Boolean,
        onBrowserExtensionIcons: Boolean,
        onPageExtensionIcons: Boolean
    ) {
        try {
            val extensions = components.core.store.state.extensions.values.filter { it.enabled }

            extensions.forEach { extension ->
                val browserAction = extension.browserAction
                val pageAction = extension.pageAction

                // Sync browser action
                if (browserAction != null) {
                    if (onBrowserExtensionsChange) {
                        val data = WebExtensionData(
                            extensionId = extension.id,
                            title = browserAction.title,
                            enabled = browserAction.enabled,
                            badgeText = browserAction.badgeText,
                            badgeTextColor = browserAction.badgeTextColor?.toLong(),
                            badgeBackgroundColor = browserAction.badgeBackgroundColor?.toLong(),
                        )
                        components.addonEvents.onUpsertWebExtensionAction(
                            EventSequence.next(),
                            extension.id,
                            WebExtensionActionType.BROWSER,
                            data
                        ) { }
                    }

                    if (onBrowserExtensionIcons) {
                        coroutineScope.launch(Dispatchers.Main) {
                            try {
                                val icon = browserAction.loadIcon?.invoke(128)
                                icon?.let {
                                    val imageBytes = icon.toWebPBytes()
                                    components.addonEvents.onUpdateWebExtensionIcon(
                                        EventSequence.next(),
                                        extension.id,
                                        WebExtensionActionType.BROWSER,
                                        imageBytes
                                    ) { }
                                }
                            } catch (e: Exception) {
                                logger.error("$TAG: Failed to load browser action icon for ${extension.id}", e)
                            }
                        }
                    }
                }

                // Sync page action
                if (pageAction != null && pageAction.enabled == true) {
                    if (onPageExtensionsChange) {
                        val data = WebExtensionData(
                            extensionId = extension.id,
                            title = pageAction.title,
                            enabled = pageAction.enabled,
                            badgeText = pageAction.badgeText,
                            badgeTextColor = pageAction.badgeTextColor?.toLong(),
                            badgeBackgroundColor = pageAction.badgeBackgroundColor?.toLong(),
                        )
                        components.addonEvents.onUpsertWebExtensionAction(
                            EventSequence.next(),
                            extension.id,
                            WebExtensionActionType.PAGE,
                            data
                        ) { }
                    }

                    if (onPageExtensionIcons) {
                        coroutineScope.launch(Dispatchers.Main) {
                            try {
                                val icon = pageAction.loadIcon?.invoke(128)
                                icon?.let {
                                    val imageBytes = icon.toWebPBytes()
                                    components.addonEvents.onUpdateWebExtensionIcon(
                                        EventSequence.next(),
                                        extension.id,
                                        WebExtensionActionType.PAGE,
                                        imageBytes
                                    ) { }
                                }
                            } catch (e: Exception) {
                                logger.error("$TAG: Failed to load page action icon for ${extension.id}", e)
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            logger.error("$TAG: Failed to sync extension events", e)
        }
    }

    override fun selectTab(tabId: String) {
        try {
            components.useCases.tabsUseCases.selectTab(tabId = tabId)
            logger.debug("$TAG: Selected tab $tabId")
        } catch (e: Exception) {
            logger.error("$TAG: Failed to select tab $tabId", e)
            throw e
        }
    }

    override fun removeTab(tabId: String) {
        try {
            components.useCases.tabsUseCases.removeTab(tabId = tabId)
            logger.debug("$TAG: Removed tab $tabId")
        } catch (e: Exception) {
            logger.error("$TAG: Failed to remove tab $tabId", e)
            throw e
        }
    }

    override fun addTab(
        url: String,
        selectTab: Boolean,
        startLoading: Boolean,
        parentId: String?,
        flags: LoadUrlFlagsValue,
        contextId: String?,
        source: SourceValue,
        private: Boolean,
        historyMetadata: PigeonHistoryMetadataKey?,
        additionalHeaders: Map<String, String>?,
        excludeFromHistory: Boolean,
        tabId: String?
    ): String {
        try {
            val loadFlags = EngineSession.LoadUrlFlags.select(flags.value.toInt())

            if (tabId != null && components.core.store.state.findTab(tabId) != null) {
                throw IllegalArgumentException("tab id already exists")
            }

            // Inlined from TabsUseCases.AddNewTabUseCase so the exclusion can be
            // marked *between* creating the tab and dispatching it, exactly as
            // addMultipleTabs does. `Store.dispatch` runs the middleware chain
            // synchronously on the calling thread, so by the time the use case
            // returned an id, HistoryMetadataMiddleware had already observed
            // AddTabAction and written the tab's first Places metadata — and with
            // the id still unmarked, a container without cookie isolation has no
            // contextId to be recognised by either.
            val tab = createTab(
                url = url,
                private = private,
                source = restoreSource(source),
                contextId = contextId,
                parent = parentId?.let { components.core.store.state.findTab(it) },
                historyMetadata = historyMetadata?.let { metadata ->
                    HistoryMetadataKey(
                        url = metadata.url,
                        searchTerm = metadata.searchTerm,
                        referrerUrl = metadata.referrerUrl
                    )
                },
                initialLoadFlags = loadFlags,
                initialAdditionalHeaders = additionalHeaders,
                desktopMode = components.core.store.state.desktopMode,
                id = tabId ?: UUID.randomUUID().toString(),
            )

            if (excludeFromHistory) {
                HistoryExclusions.markProvisional(tab.id)
            }

            components.core.store.dispatch(
                TabListAction.AddTabAction(tab, select = selectTab)
            )

            if (startLoading) {
                components.core.store.dispatch(
                    EngineAction.LoadUrlAction(
                        tabId = tab.id,
                        url = url,
                        flags = loadFlags,
                        additionalHeaders = additionalHeaders,
                        includeParent = true
                    )
                )
            }

            logger.debug("$TAG: Added new tab with ID ${tab.id}")
            return tab.id
        } catch (e: Exception) {
            logger.error("$TAG: Failed to add tab", e)
            throw e
        }
    }

    override fun removeAllTabs(recoverable: Boolean) {
        try {
            components.useCases.tabsUseCases.removeAllTabs(recoverable = recoverable)
            logger.debug("$TAG: Removed all tabs, recoverable: $recoverable")
        } catch (e: Exception) {
            logger.error("$TAG: Failed to remove all tabs", e)
            throw e
        }
    }

    override fun removeTabs(ids: List<String>) {
        try {
            components.useCases.tabsUseCases.removeTabs(ids = ids)
            logger.debug("$TAG: Removed tabs: ${ids.joinToString()}")
        } catch (e: Exception) {
            logger.error("$TAG: Failed to remove tabs", e)
            throw e
        }
    }

    override fun removeNormalTabs() {
        try {
            components.useCases.tabsUseCases.removeNormalTabs()
            logger.debug("$TAG: Removed all normal tabs")
        } catch (e: Exception) {
            logger.error("$TAG: Failed to remove normal tabs", e)
            throw e
        }
    }

    override fun removePrivateTabs() {
        try {
            components.useCases.tabsUseCases.removePrivateTabs()
            logger.debug("$TAG: Removed all private tabs")
        } catch (e: Exception) {
            logger.error("$TAG: Failed to remove private tabs", e)
            throw e
        }
    }

    override fun undo() {
        try {
            components.useCases.tabsUseCases.undo()
            logger.debug("$TAG: Performed undo operation")
        } catch (e: Exception) {
            logger.error("$TAG: Failed to perform undo", e)
            throw e
        }
    }

    override fun restoreTabsByList(
        tabs: List<PigeonRecoverableTab>,
        selectTabId: String?,
        restoreLocation: PigeonRestoreLocation
    ) {
        try {
            components.useCases.tabsUseCases.restore(
                tabs = tabs.map { mapTab(it) },
                restoreLocation = mapRestoreLocation(restoreLocation),
                selectTabId = selectTabId
            )
            logger.debug("$TAG: Restored ${tabs.size} tabs")
        } catch (e: Exception) {
            logger.error("$TAG: Failed to restore tabs", e)
            throw e
        }
    }

    // The two selectOrAddTab entry points below deliberately carry no
    // excludeFromHistory flag, unlike addTab/addMultipleTabs/duplicateTab. Neither
    // this API nor AC's SelectOrAddUseCase takes a contextId, so a tab created
    // here has none — and Dart's `syncTabs` inserts the row it discovers with no
    // container_id. The tab is therefore uncontained in both stores and correctly
    // records history; there is no exclusion to mark, provisional or otherwise.
    //
    // If a contextId or container is ever threaded through either method, that
    // stops being true and they need the same createTab → markProvisional →
    // dispatch shape as addTab: a tab is always absent from `knownTabIds` when
    // AddTabAction is observed, so the provisional mark is the only thing that can
    // identify it as excluded to HistoryMetadataMiddleware.
    override fun selectOrAddTabByHistory(
        url: String,
        historyMetadata: PigeonHistoryMetadataKey
    ): String {
        try {
            return components.useCases.tabsUseCases.selectOrAddTab(
                url = url,
                historyMetadata = HistoryMetadataKey(
                    url = historyMetadata.url,
                    searchTerm = historyMetadata.searchTerm,
                    referrerUrl = historyMetadata.referrerUrl
                )
            ).also {
                logger.debug("$TAG: Selected or added tab by history with ID $it")
            }
        } catch (e: Exception) {
            logger.error("$TAG: Failed to select or add tab by history", e)
            throw e
        }
    }

    override fun selectOrAddTabByUrl(
        url: String,
        private: Boolean,
        source: SourceValue,
        flags: LoadUrlFlagsValue,
        ignoreFragment: Boolean
    ): String {
        try {
            return components.useCases.tabsUseCases.selectOrAddTab(
                url = url,
                private = private,
                source = restoreSource(source),
                flags = EngineSession.LoadUrlFlags.select(flags.value.toInt()),
                ignoreFragment = ignoreFragment
            ).also {
                logger.debug("$TAG: Selected or added tab by URL with ID $it")
            }
        } catch (e: Exception) {
            logger.error("$TAG: Failed to select or add tab by URL", e)
            throw e
        }
    }

    override fun duplicateTab(
        selectTabId: String?,
        selectNewTab: Boolean,
        newContextId: String?,
        excludeFromHistory: Boolean
    ): String {
        try {
            val tabState = selectTabId?.let { components.core.store.state.findTab(it) }
                ?: throw IllegalArgumentException("Tab not found")

            val duplicate = createTab(
                url = tabState.content.url,
                private = tabState.content.private,
                contextId = newContextId,
                parent = tabState,
                engineSessionState = tabState.engineState.engineSessionState,
            )

            // Before dispatching: the duplicate carries the source's URL, so
            // HistoryMetadataMiddleware writes its Places metadata while handling
            // AddTabAction — synchronously, inside the dispatch below. See addTab.
            if (excludeFromHistory) {
                HistoryExclusions.markProvisional(duplicate.id)
            }

            components.core.store.dispatch(
                TabListAction.AddTabAction(
                    duplicate,
                    select = selectNewTab,
                ),
            )

            logger.debug("$TAG: Duplicated tab $selectTabId to new tab ${duplicate.id}")

            return duplicate.id
        } catch (e: Exception) {
            logger.error("$TAG: Failed to duplicate tab", e)
            throw e
        }
    }

    override fun moveTabs(tabIds: List<String>, targetTabId: String, placeAfter: Boolean) {
        try {
            components.useCases.tabsUseCases.moveTabs(
                tabIds = tabIds,
                targetTabId = targetTabId,
                placeAfter = placeAfter
            )
            logger.debug("$TAG: Moved tabs ${tabIds.joinToString()} to $targetTabId")
        } catch (e: Exception) {
            logger.error("$TAG: Failed to move tabs", e)
            throw e
        }
    }

    override fun migratePrivateTabUseCase(tabId: String, alternativeUrl: String?): String {
        try {
            return components.useCases.tabsUseCases.migratePrivateTabUseCase(
                tabId = tabId,
                alternativeUrl = alternativeUrl
            ).also {
                logger.debug("$TAG: Migrated private tab $tabId")
            }
        } catch (e: Exception) {
            logger.error("$TAG: Failed to migrate private tab", e)
            throw e
        }
    }

    override fun addMultipleTabs(
        tabs: List<AddTabParams>,
        selectTabId: String?,
        excludeFromHistory: Boolean
    ): List<String> {
        try {
            tabs.forEach { params ->
                if (params.tabId != null && components.core.store.state.findTab(params.tabId) != null) {
                    throw IllegalArgumentException("tab id already exists")
                }
            }

            val tabSessionStates = tabs.map { params ->
                createTab(
                    url = params.url,
                    private = params.private,
                    source = restoreSource(params.source),
                    contextId = params.contextId,
                    //ParentId currently not supported for multiple tabs
                    //parent = params.parentId?.let { components.core.store.state.findTab(it) },
                    historyMetadata = params.historyMetadata?.let { metadata ->
                        HistoryMetadataKey(
                            url = metadata.url,
                            searchTerm = metadata.searchTerm,
                            referrerUrl = metadata.referrerUrl
                        )
                    },
                    desktopMode = components.core.store.state.desktopMode,
                    id = params.tabId ?: UUID.randomUUID().toString(),
                )
            }

            // Before the tabs are dispatched (and therefore before any of them can
            // load): see addTab.
            if (excludeFromHistory) {
                tabSessionStates.forEach { HistoryExclusions.markProvisional(it.id) }
            }

            components.core.store.dispatch(
                TabListAction.AddMultipleTabsAction(
                    tabs = tabSessionStates
                )
            )

            // Load URLs for tabs that need loading
            tabs.zip(tabSessionStates).forEach { (params, tabState) ->
                if (params.startLoading) {
                    components.core.store.dispatch(
                        EngineAction.LoadUrlAction(
                            tabId = tabState.id,
                            url = params.url,
                            flags = EngineSession.LoadUrlFlags.select(params.flags.value.toInt()),
                            additionalHeaders = params.additionalHeaders,
                            includeParent = true
                        )
                    )
                }
            }

            selectTabId?.let {
                components.useCases.tabsUseCases.selectTab(tabId = it)
            }

            val createdTabIds = tabSessionStates.map { it.id }
            logger.debug("$TAG: Added ${tabs.size} tabs: ${createdTabIds.joinToString()}")
            return createdTabIds
        } catch (e: Exception) {
            logger.error("$TAG: Failed to add multiple tabs", e)
            throw e
        }
    }
}
