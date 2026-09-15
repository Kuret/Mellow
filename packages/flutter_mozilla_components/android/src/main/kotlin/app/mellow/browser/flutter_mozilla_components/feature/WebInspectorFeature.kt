/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package app.mellow.browser.flutter_mozilla_components.feature

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.map
import mozilla.components.browser.state.selector.findTab
import mozilla.components.browser.state.selector.selectedTab
import mozilla.components.browser.state.store.BrowserStore
import mozilla.components.concept.engine.Engine
import mozilla.components.concept.engine.webextension.MessageHandler
import mozilla.components.concept.engine.webextension.Port
import mozilla.components.lib.state.ext.flowScoped
import mozilla.components.support.base.feature.LifecycleAwareFeature
import mozilla.components.support.base.log.logger.Logger
import mozilla.components.support.ktx.kotlinx.coroutines.flow.filterChanged
import mozilla.components.support.webextensions.BuiltInWebExtensionController
import org.json.JSONObject

/**
 * Installs the built-in web inspector extension (a vendored Eruda) and gives the
 * app an imperative channel to drive it per tab.
 */
class WebInspectorFeature(
    private var engine: Engine,
    private var store: BrowserStore
) : LifecycleAwareFeature {
    companion object {
        private val logger = Logger("WebInspector")

        internal const val WEB_INSPECTOR_EXTENSION_ID = "web-inspector@weblibre.eu"
        internal const val WEB_INSPECTOR_CONTENT_PORT = "mozacWebInspector"
        internal const val WEB_INSPECTOR_EXTENSION_URL =
            "resource://android/assets/extensions/web_inspector/"
    }

    private class ContentMessageHandler(
        private var tabId: String
    ) : MessageHandler {
        override fun onPortConnected(port: Port) {
            logger.debug("Port connected: ${port.name()} (tab $tabId)")
        }

        override fun onPortMessage(message: Any, port: Port) {
            logger.debug("Message from web inspector (tab $tabId): $message")
        }
    }

    private var sessionScope: CoroutineScope? = null

    private var extensionController = BuiltInWebExtensionController(
        WEB_INSPECTOR_EXTENSION_ID,
        WEB_INSPECTOR_EXTENSION_URL,
        WEB_INSPECTOR_CONTENT_PORT,
    )

    override fun start() {
        ensureExtensionInstalled()
    }

    override fun stop() {
        sessionScope?.cancel()
    }

    /**
     * Sends [action] to the inspector running in [tabId], or in the selected tab
     * when [tabId] is null. Returns quietly when the tab has no engine session or
     * the content port is not connected yet.
     */
    fun send(tabId: String?, action: String, panel: String? = null) {
        val tab = if (tabId != null) {
            store.state.findTab(tabId)
        } else {
            store.state.selectedTab
        }

        val engineSession = tab?.engineState?.engineSession ?: return

        if (!extensionController.portConnected(engineSession)) {
            logger.debug("Web inspector port not connected, dropping action '$action'")
            return
        }

        val message = JSONObject().put("action", action)
        if (panel != null) {
            message.put("panel", panel)
        }

        extensionController.sendContentMessage(message, engineSession)
    }

    private fun ensureExtensionInstalled() {
        extensionController.install(
            engine,
            onSuccess = { extension ->
                sessionScope = store.flowScoped(dispatcher = Dispatchers.Main) { flow ->
                    flow.map { it.tabs }
                        .filterChanged { it.engineState.engineSession }
                        .collect { state ->
                            val engineSession = state.engineState.engineSession ?: return@collect

                            if (extension.hasContentMessageHandler(engineSession, WEB_INSPECTOR_CONTENT_PORT)) {
                                return@collect
                            }

                            val handler = ContentMessageHandler(state.id)
                            extension.registerContentMessageHandler(engineSession, WEB_INSPECTOR_CONTENT_PORT, handler)
                        }
                }
            },
            onError = { throwable ->
                Logger.error("Could not install $WEB_INSPECTOR_EXTENSION_ID extension", throwable)
            },
        )
    }
}
