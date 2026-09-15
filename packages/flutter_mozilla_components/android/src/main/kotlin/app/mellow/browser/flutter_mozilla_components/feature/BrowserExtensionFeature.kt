/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package eu.weblibre.flutter_mozilla_components.feature

import androidx.annotation.VisibleForTesting
import eu.weblibre.flutter_mozilla_components.ext.EventSequence
import eu.weblibre.flutter_mozilla_components.pigeons.BrowserExtensionEvents
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import mozilla.components.concept.engine.webextension.MessageHandler
import mozilla.components.concept.engine.webextension.Port
import mozilla.components.concept.engine.webextension.WebExtensionRuntime
import mozilla.components.support.base.log.logger.Logger
import mozilla.components.support.webextensions.BuiltInWebExtensionController
import org.json.JSONArray
import org.json.JSONObject
import org.mozilla.gecko.util.ThreadUtils.runOnUiThread

object BrowserExtensionFeature {
    private val logger = Logger("browser_extension")

    private const val PREF_MANAGER_REPORTER_EXTENSION_ID = "browser_extension@weblibre.eu"
    private const val PREF_MANAGER_REPORTER_EXTENSION_URL =
        "resource://android/assets/extensions/browser_extension/"
    private const val PREF_MANAGER_REPORTER_MESSAGING_ID = "mozacBrowserExtension"

    private var nextRequestId: Int = 0
    private val requestHandlers = HashMap<Int, ResultConsumer<JSONObject>>()
    private val mutex = Mutex()

    /**
     * Whether this extension's background script has connected its native port
     * at any point in this process.
     *
     * Not about anything this extension does — it is the cheapest proof
     * available that Gecko ran the delayed startup it gates on a chrome window
     * existing: a background script cannot run before `extensions-late-startup`
     * fires, and that notification releases *every* extension's background at
     * once. [EngineWarmupSession][eu.weblibre.flutter_mozilla_components.startup.EngineWarmupSession]
     * watches it to know its job is done.
     *
     * Latched, unlike everything else here: it answers "did that ever happen",
     * not "is a port up now", so a background restart must not clear it.
     */
    private val extensionBackgroundStartedState = MutableStateFlow(false)

    /** See [extensionBackgroundStartedState]. */
    internal val extensionBackgroundStarted: StateFlow<Boolean> =
        extensionBackgroundStartedState.asStateFlow()

    @VisibleForTesting
    // This is an internal var to make it mutable for unit testing purposes only
    internal var extensionController = BuiltInWebExtensionController(
        PREF_MANAGER_REPORTER_EXTENSION_ID,
        PREF_MANAGER_REPORTER_EXTENSION_URL,
        PREF_MANAGER_REPORTER_MESSAGING_ID
    )

    fun scheduleRequest(
        command: String,
        args: Any,
        callback: ResultConsumer<JSONObject>
    ) {
        val message = JSONObject()
        message.put("action", command);
        message.put(
            "args", when (args) {
                is List<*> -> JSONArray(args)
                else -> args
            }
        )

        runBlocking {
            withContext(Dispatchers.Default) {
                mutex.withLock {
                    message.put("id", nextRequestId)

                    requestHandlers[nextRequestId] = callback

                    nextRequestId += 1

                    extensionController.sendBackgroundMessage(message)
                }
            }
        }
    }

    private class ExtensionBackgroundMessageHandler(
        private val extensionEvents: BrowserExtensionEvents
    ) : MessageHandler {
        override fun onPortConnected(port: Port) {
            // Latched, never cleared: see [extensionBackgroundStartedState].
            extensionBackgroundStartedState.value = true
        }

        override fun onPortMessage(message: Any, port: Port) {
            runBlocking {
                withContext(Dispatchers.Default) {
                    mutex.withLock {
                        val messageJSON = message as JSONObject;
                        val type = messageJSON.getString("type")

                        if (type == "turndown") {
                            val requestId = messageJSON.getInt("id")
                            val status = messageJSON.getString("status")
                            val handler = requestHandlers.remove(requestId)
                            if (status == "success") {
                                handler?.success(message)
                            } else {
                                handler?.error(
                                    "Pref Manager",
                                    "Failed to perform operation",
                                    message.getString("error")
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     * Installs the web extension in the runtime through the WebExtensionRuntime install method
     *
     * @param runtime a WebExtensionRuntime.
     * @param productName a custom product name used to automatically label reports. Defaults to
     * "android-components".
     */
    fun install(runtime: WebExtensionRuntime, extensionEvents: BrowserExtensionEvents) {
        extensionController.registerBackgroundMessageHandler(
            ExtensionBackgroundMessageHandler(extensionEvents)
        )
        extensionController.install(
            runtime,
            onSuccess = {
                logger.debug("Installed browser_extension webextension: ${it.id}")
            },
            onError = { throwable ->
                logger.error("Failed to install browser_extension webextension: ", throwable)
            },
        )
    }
}
