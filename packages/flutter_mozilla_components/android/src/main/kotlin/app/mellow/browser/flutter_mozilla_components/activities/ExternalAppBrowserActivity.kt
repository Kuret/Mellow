/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package app.mellow.browser.flutter_mozilla_components.activities

import android.app.Dialog
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.View
import androidx.activity.addCallback
import androidx.annotation.VisibleForTesting
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import androidx.lifecycle.Lifecycle
import app.mellow.browser.flutter_mozilla_components.ColorSchemePreference
import app.mellow.browser.flutter_mozilla_components.ExternalAppBrowserFragment
import app.mellow.browser.flutter_mozilla_components.FlutterEngineCoordinator
import app.mellow.browser.flutter_mozilla_components.GlobalComponents
import app.mellow.browser.flutter_mozilla_components.HomePressDispatcher
import app.mellow.browser.flutter_mozilla_components.PwaConstants
import app.mellow.browser.flutter_mozilla_components.PwaSessionCreator
import app.mellow.browser.flutter_mozilla_components.addons.WebExtensionPromptHost
import app.mellow.browser.flutter_mozilla_components.lock.ExternalWindowLock
import app.mellow.browser.flutter_mozilla_components.lock.LockedWindowCurtain
import app.mellow.browser.flutter_mozilla_components.lock.ProfileLockedWindow
import app.mellow.browser.flutter_mozilla_components.lock.ProfileUnlockRegistry
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
open class ExternalAppBrowserActivity : AppCompatActivity(), ProfileLockedWindow {
    companion object {
        private const val TAG = "ExternalAppBrowserActivity"

        const val EXTRA_CUSTOM_TAB_SESSION_ID = "custom_tab_session_id"
        const val EXTRA_WEB_APP_MANIFEST_URL = "web_app_manifest_url"

        /** How [recoverPwaSession] creates a lost PWA session again. */
        @VisibleForTesting
        internal var createPwaSession: suspend (
            url: String,
            contextId: String?,
            desktopMode: Boolean?,
        ) -> String = PwaSessionCreator::create

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
            pwaDesktopMode: Boolean? = null,
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
                pwaDesktopMode?.let { putExtra(PwaConstants.EXTRA_PWA_DESKTOP_MODE, it) }
            }
        }
    }

    private val logger = Logger("ExternalAppBrowserActivity")
    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var isRecoveringPwaSession = false

    /**
     * Whether this window is only ever opened by the browser, from a screen
     * that is itself behind the profile lock.
     *
     * Such a window opens unlocked, as a continuation of what the person was
     * doing, and locks like any other once they leave it. Only a fresh launch
     * counts: reopening it from recents is a new visit.
     */
    protected open val opensFromUnlockedBrowser: Boolean = false

    /** Null only before `setContentView`, which it needs. */
    private var windowLock: ExternalWindowLock? = null

    /** Null only before `onCreate`. */
    private var curtain: LockedWindowCurtain? = null

    /** Whether [start] ran: the profile was open when this window began. */
    private var started = false

    /**
     * Custom tabs moving to new components while this window is open; see
     * [onCustomTabsHandedOver]. Acts only while a fragment transaction is
     * allowed, and keeps the rest for [onResume].
     */
    private val handover = HandoverWait(
        timeoutMs = PwaConstants.COMPONENT_INIT_TIMEOUT_MS,
        schedule = { delayMs, block ->
            val job = coroutineScope.launch {
                delay(delayMs)
                block()
            }
            ({ job.cancel() })
        },
        mayAct = {
            !supportFragmentManager.isStateSaved &&
                lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)
        },
    )

    private val customTabsHandoverListener: () -> Unit = { onCustomTabsHandedOver() }

    /**
     * What [showFragment] was asked to show while fragment transactions were
     * not allowed, for [onResume]. The latest request wins.
     */
    private var deferredShow: (() -> Unit)? = null

    /** Paused into picture-in-picture, which is not leaving yet. */
    private var pausedIntoPictureInPicture = false

    /** This window in [ProfileUnlockRegistry]'s pending departures. */
    private val departureToken = Any()

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
            // Not the page's back history: that belongs to whoever unlocks it.
            if (windowLock?.isShowing == true) {
                finishAndRemoveTask()
                return@addCallback
            }

            val fragment = supportFragmentManager.findFragmentById(R.id.container)
            if (fragment is UserInteractionHandler && fragment.onBackPressed()) {
                return@addCallback
            }

            finishAndRemoveTask()
        }

        WindowCompat.setDecorFitsSystemWindows(window, false)
        setContentView(R.layout.activity_external_app_browser)

        // Before the lock, which reports to it, and before `onStart`, which
        // shows the dialogs `super.onCreate` restored.
        curtain = LockedWindowCurtain(supportFragmentManager)

        // Before anything of the profile is shown or started: a Custom Tab or
        // PWA never passes through the browser's lock screen, so a locked
        // profile is locked here as well (issue #658).
        val lock = ExternalWindowLock(
            activity = this,
            scope = coroutineScope,
            onClose = { finishAndRemoveTask() },
            onLockChanged = ::onLockChanged,
        )
        windowLock = lock

        val freshLaunch = savedInstanceState == null &&
            ((intent?.flags ?: 0) and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) == 0
        if (opensFromUnlockedBrowser && freshLaunch) {
            lock.grantForLaunch()
        }

        GlobalComponents.addCustomTabsHandoverListener(customTabsHandoverListener)

        lock.guard(autoPrompt = false) { start() }
    }

    override val isProfileLocked: Boolean
        get() = windowLock?.isShowing == true

    override fun coverWhileLocked(dialog: Dialog) {
        curtain?.cover(dialog)
    }

    /**
     * Hides everything above the lock panel that the panel cannot cover:
     * windows of their own, which a page or the window's own controls put up.
     */
    private fun onLockChanged(locked: Boolean) {
        if (locked) {
            curtain?.lock()
            (supportFragmentManager.findFragmentById(R.id.container) as? ExternalAppBrowserFragment)
                ?.onWindowLocked()
        } else {
            curtain?.unlock()
        }

        // Install prompts wait in the store while the window is locked.
        WebExtensionPromptHost.onWindowLockChanged(this)
    }

    /** What the window does once its profile is open. */
    private fun start() {
        started = true

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

    override fun onPause() {
        super.onPause()

        // A rotation is not leaving.
        if (isChangingConfigurations) return

        // Neither is picture-in-picture: the video is still on screen, and
        // covering it would end what the person asked for. Leaving happens
        // when that window goes away without coming back, see [onStop].
        if (isInPictureInPictureMode) {
            pausedIntoPictureInPicture = true
            return
        }

        // Not leaving yet: a dialog may only be drawing over the window. See
        // [ProfileUnlockRegistry.windowPaused].
        ProfileUnlockRegistry.windowPaused(departureToken, ::coverAfterLeaving)
    }

    override fun onStop() {
        super.onStop()

        if (isChangingConfigurations) return

        if (pausedIntoPictureInPicture) {
            pausedIntoPictureInPicture = false
            ProfileUnlockRegistry.windowLeft(::coverAfterLeaving)
            return
        }

        ProfileUnlockRegistry.windowStopped(departureToken)
    }

    /**
     * Leaving ended a background-mode unlock, for this window and every other
     * one. Covered as soon as that is settled, so the page is not what the
     * next person to look at this window sees first.
     */
    private fun coverAfterLeaving() {
        if (started && !isDestroyed) {
            windowLock?.guard(autoPrompt = false)
        }
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

    /**
     * [mayAwaitHandover] is false once a wait for the handover gave up: the
     * session is then decided on as lost, rather than waited for again.
     */
    private fun showFragment(sessionId: String, mayAwaitHandover: Boolean = true) {
        // Asked for by continuations (a recovered PWA session, the waits for
        // components, routing or the handover) that can finish after the
        // window went to the background. A commit after `onSaveInstanceState`
        // throws, so the request waits for the window, with the session it
        // names; so does every decision below, starting activities included.
        if (supportFragmentManager.isStateSaved) {
            deferredShow = { showFragment(sessionId, mayAwaitHandover) }
            return
        }

        hideLaunchStatus()

        val components = GlobalComponents.components ?: run {
            logger.error("Components still null after waiting, finishing.")
            finish()
            return
        }

        // Verify session exists
        if (components.core.store.state.findCustomTab(sessionId) == null) {
            if (mayAwaitHandover && GlobalComponents.isHandingOverCustomTabs) {
                // The app half started (a password check starts it) and its
                // components take this window's session over only once they
                // have restored the browser's tabs. Missing for that long is
                // not gone. A handover that never finishes must not leave a
                // blank window, though: past the components timeout, this
                // decides again without waiting.
                handover.await { showFragment(sessionId, mayAwaitHandover = false) }
                return
            }

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

    /**
     * Custom tabs moved to new components: the app half started while this
     * window was open and replaced the external set (issue #658: a password
     * check starts it).
     */
    private fun onCustomTabsHandedOver() {
        if (!started || isFinishing || isDestroyed) return
        handover.arrived(::applyHandover)
    }

    private fun applyHandover(endedWait: Boolean) {
        val sessionId = customTabSessionId ?: return

        if (endedWait) {
            showFragment(sessionId)
            return
        }

        // A fragment built before the handover keeps the outgoing components:
        // its features watch a store the page no longer reports to, so its
        // URL, back state and prompts would go stale. One built since is fine.
        val fragment =
            supportFragmentManager.findFragmentById(R.id.container) as? ExternalAppBrowserFragment
                ?: return
        val bound = fragment.boundComponents ?: return
        if (bound === GlobalComponents.components) return

        fragment.releaseSession()
        showFragment(sessionId)
    }

    override fun onResume() {
        super.onResume()

        // Back from picture-in-picture, or through it: either way, here again.
        pausedIntoPictureInPicture = false

        // Before the guard: settles whether this window left, and whether the
        // one it took the front from did.
        ProfileUnlockRegistry.windowResumed(departureToken)

        // A window this very guard starts has just checked its session.
        val wasStarted = started
        windowLock?.guard(autoPrompt = true)
        if (!wasStarted) return

        // What could not be shown, or done for the handover, while the window
        // was away. The handover second: it leaves a fragment that is already
        // on the current components alone.
        val shown = deferredShow?.let { show ->
            deferredShow = null
            show()
            true
        } ?: false
        val handedOver = handover.runDeferred()
        if (shown || handedOver) return

        // Mid-handover the session is missing from the new components without
        // being gone; [onCustomTabsHandedOver] picks it up.
        if (GlobalComponents.isHandingOverCustomTabs) return

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
            // Only the creation can fail the recovery. Showing the session
            // is not part of it: a failure there must not remove a task
            // whose session exists.
            val sessionId = try {
                createPwaSession(
                    launchUrl,
                    contextId,
                    PwaSessionCreator.desktopModeOf(intent),
                )
            } catch (e: Exception) {
                Log.e(TAG, "Failed to recover PWA session", e)
                logger.error("Failed to recover PWA session, removing stale task.", e)
                if (!isFinishing && !isDestroyed) {
                    finishAndRemoveTask()
                }
                return@launch
            } finally {
                isRecoveringPwaSession = false
            }

            Log.d(
                TAG,
                "Recovered PWA session: old=$missingSessionId, new=$sessionId, url=$launchUrl",
            )

            intent.putExtra(EXTRA_CUSTOM_TAB_SESSION_ID, sessionId)
            if (webAppManifestUrl == null) {
                intent.putExtra(EXTRA_WEB_APP_MANIFEST_URL, launchUrl)
            }

            if (!isFinishing && !isDestroyed) {
                // Deferred to `onResume` if the window went away meanwhile.
                showFragment(sessionId)
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

        // Normally settled by `onStop` already; this only drops a pause that
        // never got that far.
        ProfileUnlockRegistry.windowStopped(departureToken)
        GlobalComponents.removeCustomTabsHandoverListener(customTabsHandoverListener)
        handover.cancel()

        FlutterEngineCoordinator.releaseForExternalTask()

        // Cancel any pending coroutines
        coroutineScope.cancel()

        // Only clean up when the activity is actually finishing (user closed it),
        // not when the system temporarily destroys it (e.g. switching to main app).
        if (isFinishing) {
            // Mid-handover too, where it is still in the outgoing store.
            customTabSessionId?.let(GlobalComponents::removeCustomTab)
        }
    }

}
