/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package app.mellow.browser.flutter_mozilla_components.activities

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.View
import androidx.activity.addCallback
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import app.mellow.browser.flutter_mozilla_components.ColorSchemePreference
import app.mellow.browser.flutter_mozilla_components.ExternalAppBrowserFragment
import app.mellow.browser.flutter_mozilla_components.FlutterEngineCoordinator
import app.mellow.browser.flutter_mozilla_components.GlobalComponents
import app.mellow.browser.flutter_mozilla_components.HomePressDispatcher
import app.mellow.browser.flutter_mozilla_components.PwaConstants
import app.mellow.browser.flutter_mozilla_components.PwaSessionCreator
import app.mellow.browser.flutter_mozilla_components.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import mozilla.components.browser.state.selector.findCustomTab
import mozilla.components.support.base.feature.UserInteractionHandler
import mozilla.components.support.base.log.logger.Logger

/**
 * Native activity that hosts [ExternalAppBrowserFragment] for Custom Tab and PWA sessions.
 * This is a non-Flutter activity — it renders GeckoView directly in a native layout.
 *
 * Uses an empty taskAffinity so Custom Tabs appear as a separate task from the main app.
 */
open class ExternalAppBrowserActivity : AppCompatActivity() {
    companion object {
        private const val TAG = "ExternalAppBrowserActivity"

        const val EXTRA_CUSTOM_TAB_SESSION_ID = "custom_tab_session_id"
        const val EXTRA_WEB_APP_MANIFEST_URL = "web_app_manifest_url"

        /**
         * Whether this window's session is a private one, in the shape the
         * intent processors already carry it.
         *
         * Set by whoever created the session, because the one place that needs
         * it here — the routing decision taken when the system hands the task
         * back to a process that has since been killed — runs before there is a
         * session to ask. A plan made in the general context for a private
         * launch is a plan about someone else's routing: `private` inherits
         * nothing from `general`, so a direct general relation would wave a
         * blocked launch straight onto a proxy error page, and a blocked one
         * would bounce a perfectly serviceable launch to the browser.
         */
        private const val PRIVATE_BROWSING_MODE = "private_browsing_mode"

        fun createIntent(
            context: Context,
            customTabSessionId: String,
            webAppManifestUrl: String? = null,
            pwaProfileUuid: String? = null,
            pwaContextId: String? = null,
            pwaToken: String? = null,
            pwaInstallStartUrl: String? = null,
            isPrivate: Boolean = false,
        ): Intent {
            return Intent(context, ExternalAppBrowserActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_DOCUMENT or Intent.FLAG_ACTIVITY_MULTIPLE_TASK
                putExtra(EXTRA_CUSTOM_TAB_SESSION_ID, customTabSessionId)
                putExtra(PRIVATE_BROWSING_MODE, isPrivate)
                webAppManifestUrl?.let { putExtra(EXTRA_WEB_APP_MANIFEST_URL, it) }
                pwaProfileUuid?.let { putExtra(PwaConstants.EXTRA_PWA_PROFILE_UUID, it) }
                pwaContextId?.let { putExtra(PwaConstants.EXTRA_PWA_CONTEXT_ID, it) }
                pwaToken?.let { putExtra(PwaConstants.EXTRA_PWA_TOKEN, it) }
                pwaInstallStartUrl?.let {
                    putExtra(PwaConstants.EXTRA_PWA_INSTALL_START_URL, it)
                }
            }
        }
    }

    private val logger = Logger("ExternalAppBrowserActivity")
    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var isRecoveringPwaSession = false

    private val customTabSessionId: String?
        get() = intent?.getStringExtra(EXTRA_CUSTOM_TAB_SESSION_ID)

    private val webAppManifestUrl: String?
        get() = intent?.getStringExtra(EXTRA_WEB_APP_MANIFEST_URL)

    override fun onCreate(savedInstanceState: Bundle?) {
        // Match the window chrome (status/nav bar + pre-paint background) to the
        // user's Mellow color scheme rather than just the system mode, so a
        // cold-started Custom Tab / PWA doesn't flash dark when Mellow is light.
        // Set before super.onCreate so the correct mode is applied without a recreate.
        delegate.localNightMode = ColorSchemePreference.nightMode(this)

        super.onCreate(savedInstanceState)

        // This task can outlive `MainActivity`, so the shared engine has to as
        // well for as long as this task exists — see
        // [FlutterEngineCoordinator.retainForExternalTask].
        FlutterEngineCoordinator.retainForExternalTask()

        onBackPressedDispatcher.addCallback(this) {
            val fragment = supportFragmentManager.findFragmentById(R.id.container)
            if (fragment is UserInteractionHandler && fragment.onBackPressed()) {
                return@addCallback
            }

            finishAndRemoveTask()
        }

        WindowCompat.setDecorFitsSystemWindows(window, false)
        setContentView(R.layout.activity_external_app_browser)

        val sessionId = customTabSessionId
        if (sessionId == null) {
            Log.e(TAG, "No custom tab session ID provided")
            logger.error("No custom tab session ID provided, finishing.")
            if (!recoverPwaSession(null, "missing session ID")) {
                fallbackToMainActivity()
            }
            return
        }

        val components = GlobalComponents.components
        if (components == null) {
            // The process this task belonged to is gone — the system handed the
            // task back and nothing has been built in the new one yet. That makes
            // this a cold start like any other.
            startWithExistingComponents(sessionId)
            return
        }

        showFragment(sessionId)
    }

    /**
     * The URL this window is for, for as long as it has no session to ask.
     *
     * Named apart from [recoverPwaSession]'s own local: that one is the URL a
     * session is about to be created for and must exist, this one is only what
     * the window says it is showing.
     */
    private val windowLaunchUrl: String?
        get() = webAppManifestUrl
            ?: intent?.getStringExtra(PwaConstants.EXTRA_PWA_INSTALL_START_URL)
            ?: intent?.dataString

    private fun hideLaunchStatus() {
        findViewById<View>(R.id.launch_status)?.visibility = View.GONE
    }

    /** The original path: whatever components this process has, or none. */
    private fun startWithExistingComponents(sessionId: String) {
        if (GlobalComponents.components != null) {
            showFragment(sessionId)
            return
        }

        // Requires a committed profile rather than binding one: this Activity is
        // launched by IntentReceiverActivity, which has already classified the
        // launch and bound the right profile. Binding again here could only pick
        // a different one.
        if (GlobalComponents.ensureExternalComponents(applicationContext)) {
            showFragment(sessionId)
            return
        }

        logger.debug("Components not yet initialized, waiting...")
        waitForComponents(sessionId)
    }

    override fun onUserLeaveHint() {
        if (HomePressDispatcher.onUserLeaveHint(this)) {
            return
        }

        super.onUserLeaveHint()
    }

    private fun waitForComponents(sessionId: String) {
        coroutineScope.launch {
            var elapsedMs = 0L

            while (isActive && elapsedMs < PwaConstants.COMPONENT_INIT_TIMEOUT_MS) {
                if (GlobalComponents.components != null) {
                    showFragment(sessionId)
                    return@launch
                }

                delay(PwaConstants.COMPONENT_INIT_CHECK_INTERVAL_MS)
                elapsedMs += PwaConstants.COMPONENT_INIT_CHECK_INTERVAL_MS
            }

            // Timeout reached
            if (isActive) {
                Log.e(TAG, "Timeout waiting for components")
                logger.error("Timeout waiting for components after ${PwaConstants.COMPONENT_INIT_TIMEOUT_MS}ms")
                fallbackToMainActivity()
            }
        }
    }

    private fun showFragment(sessionId: String) {
        hideLaunchStatus()

        val components = GlobalComponents.components ?: run {
            logger.error("Components still null after waiting, finishing.")
            finish()
            return
        }

        // Verify session exists
        if (components.core.store.state.findCustomTab(sessionId) == null) {
            Log.e(TAG, "Custom tab session $sessionId not found in store")
            logger.error("Custom tab session $sessionId not found in store, finishing.")
            if (!recoverPwaSession(sessionId, "session not found in store")) {
                fallbackToMainActivity()
            }
            return
        }

        val fragment = ExternalAppBrowserFragment.create(
            customTabSessionId = sessionId,
            webAppManifestUrl = webAppManifestUrl,
        )

        supportFragmentManager.beginTransaction()
            .replace(R.id.container, fragment)
            .commit()
    }

    override fun onResume() {
        super.onResume()

        // If the session was removed while we were in the background, finish
        val sessionId = customTabSessionId ?: return
        val components = GlobalComponents.components ?: return
        if (components.core.store.state.findCustomTab(sessionId) == null) {
            Log.w(TAG, "Custom tab session $sessionId gone on resume")
            logger.debug("Custom tab session $sessionId gone, finishing activity.")
            if (!recoverPwaSession(sessionId, "session gone on resume")) {
                fallbackToMainActivity()
            }
        }
    }

    private fun recoverPwaSession(missingSessionId: String?, reason: String): Boolean {
        if (isRecoveringPwaSession) {
            return true
        }

        val launchUrl = webAppManifestUrl
            ?: intent?.getStringExtra(PwaConstants.EXTRA_PWA_INSTALL_START_URL)
            ?: return false

        val isPwaTask = webAppManifestUrl != null ||
            intent?.hasExtra(PwaConstants.EXTRA_PWA_PROFILE_UUID) == true
        if (!isPwaTask) {
            return false
        }

        val contextId = intent?.getStringExtra(PwaConstants.EXTRA_PWA_CONTEXT_ID)
        isRecoveringPwaSession = true
        Log.w(TAG, "Creating PWA session for $launchUrl: $reason")

        coroutineScope.launch {
            try {
                val sessionId = PwaSessionCreator.create(launchUrl, contextId)
                Log.d(
                    TAG,
                    "Recovered PWA session: old=$missingSessionId, new=$sessionId, url=$launchUrl",
                )

                intent.putExtra(EXTRA_CUSTOM_TAB_SESSION_ID, sessionId)
                if (webAppManifestUrl == null) {
                    intent.putExtra(EXTRA_WEB_APP_MANIFEST_URL, launchUrl)
                }

                if (!isFinishing && !isDestroyed) {
                    showFragment(sessionId)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to recover PWA session", e)
                logger.error("Failed to recover PWA session, removing stale task.", e)
                if (!isFinishing && !isDestroyed) {
                    finishAndRemoveTask()
                }
            } finally {
                isRecoveringPwaSession = false
            }
        }

        return true
    }

    /**
     * Same fallback, reachable from the window's fragment when it gives up
     * waiting for components (see `BaseBrowserFragment.onComponentsUnavailable`).
     */
    internal fun fallbackToMainActivityFromWindow() = fallbackToMainActivity()

    /**
     * Hands this launch to the ordinary browser.
     *
     * The container goes with it. A PWA belongs to one, and a URL opened in the
     * browser without it is a URL opened under different routing and different
     * cookies than the app it came from — the very thing the launch was being
     * careful about. Dart reads `pwa_context_id` off a VIEW intent and opens the
     * tab in that container (see `IntentContainerMode.fromWireValue`), which is
     * also what puts the user in front of the prompt to start its proxy.
     */
    private fun fallbackToMainActivity() {
        val url = windowLaunchUrl
        val contextId = intent?.getStringExtra(PwaConstants.EXTRA_PWA_CONTEXT_ID)

        val mainIntent = Intent().apply {
            setClassName(this@ExternalAppBrowserActivity, "app.mellow.browser.MainActivity")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (url != null) {
                action = Intent.ACTION_VIEW
                data = android.net.Uri.parse(url)
                if (contextId != null) {
                    putExtra(PwaConstants.EXTRA_PWA_CONTEXT_ID, contextId)
                }
            }
        }
        startActivity(mainIntent)
        finish()
    }

    override fun onDestroy() {
        super.onDestroy()

        FlutterEngineCoordinator.releaseForExternalTask()

        // Cancel any pending coroutines
        coroutineScope.cancel()

        // Only clean up when the activity is actually finishing (user closed it),
        // not when the system temporarily destroys it (e.g. switching to main app).
        if (isFinishing) {
            val sessionId = customTabSessionId
            if (sessionId != null) {
                val components = GlobalComponents.components
                if (components != null) {
                    val customTab = components.core.store.state.findCustomTab(sessionId)
                    if (customTab != null) {
                        components.useCases.customTabsUseCases.remove(sessionId)
                    }
                }
            }
        }
    }

}
