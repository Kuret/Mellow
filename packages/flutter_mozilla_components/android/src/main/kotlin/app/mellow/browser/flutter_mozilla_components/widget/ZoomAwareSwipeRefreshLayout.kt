/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package app.mellow.browser.flutter_mozilla_components.widget

import android.content.Context
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.ViewGroup
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout
import app.mellow.browser.flutter_mozilla_components.pointer.isSecondaryMouseButton
import kotlin.math.abs
import org.mozilla.geckoview.GeckoView

/**
 * [SwipeRefreshLayout] that only pulls to refresh for a plain vertical drag.
 *
 * Replaces android-components' `VerticalSwipeRefreshLayout`, which is `final`
 * and cannot be extended. The parts that matter are kept: horizontal-dominant
 * drags do not pull, nested scrolls from descendants are ignored, and a
 * descendant's `requestDisallowInterceptTouchEvent` is recorded here rather
 * than propagated to the parent (which uses the gesture for other purposes).
 *
 * What changes is *where* zoom gestures are detected. Upstream watches for the
 * second pointer and for the double tap that starts a quick scale inside
 * [onInterceptTouchEvent] — and that hook is skipped for most of a stroke here,
 * because `NestedGeckoView` calls `requestDisallowInterceptTouchEvent(true)` on
 * every ACTION_DOWN, which returns before either check runs. APZ answers
 * asynchronously and lifts the disallow again part-way through the stroke, so
 * what this layout ends up seeing is the *trailing* single-pointer part of a
 * pinch, measured against the ACTION_DOWN that started the pinch. That looks
 * exactly like a plain downward pull from the top of the page, and reloads it
 * on release.
 *
 * [dispatchTouchEvent] has no such gap: it runs for every event of every stroke
 * that reaches the browser content, disallow or not, and before this layout's
 * own intercept handling for the same event. Classifying there and latching the
 * verdict for the whole stroke is what makes the guard hold.
 *
 * See https://github.com/FaFre/WebLibre/issues/356.
 *
 * [dispatchTouchEvent] also claims one other, narrower case before any of the
 * above: a secondary mouse button press. GeckoView's `PanZoomController`
 * treats every mouse button delivered through `onTouchEvent` as a plain
 * touch (so a mouse can pan and zoom), and only `onMouseEvent` gives desktop
 * semantics — a `contextmenu` event in the page for a right click, which is
 * what Samsung DeX needs. Only the secondary button is diverted; the primary
 * button keeps flowing through touch dispatch, which is what the pull and
 * pinch handling above, `BrowserHandlingScrollFeature`, and nested scrolling
 * all still need.
 *
 * Derived from android-components `VerticalSwipeRefreshLayout` (MPL-2.0).
 */
class ZoomAwareSwipeRefreshLayout @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
) : SwipeRefreshLayout(context, attrs) {

    /**
     * Whether the touch sequence currently in flight is a zoom gesture: two or
     * more pointers down at any point (pinch), or an ACTION_DOWN that is the
     * second tap of a double tap (quick-scale drag-zoom, and plain double-tap
     * zoom).
     *
     * Cleared on ACTION_DOWN rather than on ACTION_UP, so it is still readable
     * while this layout runs its own up-handling — which is where a pull past
     * the threshold turns into a reload.
     */
    var strokeIsZoomGesture: Boolean = false
        private set

    private val doubleTapTimeoutMs = ViewConfiguration.getDoubleTapTimeout().toLong()
    private val doubleTapSlopSquare =
        ViewConfiguration.get(context).scaledDoubleTapSlop.toLong().let { it * it }

    // Where the stroke in flight started, and whether it has had a second
    // pointer down. Promoted to the `previous*` fields below once it ends.
    private var downX = 0f
    private var downY = 0f
    private var strokeHadMultiplePointers = false

    // The last stroke that ended in an ACTION_UP with a single pointer: where
    // it *started*, and when it ended.
    private var previousDownX = 0f
    private var previousDownY = 0f
    private var previousUpTime = 0L
    private var hasPreviousStroke = false

    private var previousX = 0f
    private var previousY = 0f
    private var disallowInterceptTouchEvent = false

    /**
     * Whether the stroke in flight was claimed at its ACTION_DOWN as a
     * secondary mouse button press and is being routed to
     * `PanZoomController.onMouseEvent` instead of the touch pipeline.
     *
     * Latched for the whole stroke so the touch pipeline never sees half a
     * gesture: MOVE/UP/CANCEL for a claimed DOWN keep going the same way,
     * regardless of what the button state reports on those later events.
     */
    private var routingSecondaryButtonGestureToGecko = false

    override fun dispatchTouchEvent(ev: MotionEvent): Boolean {
        if (routingSecondaryButtonGestureToGecko) {
            val routed = routeToGeckoMouseEvent(ev)
            if (ev.actionMasked == MotionEvent.ACTION_UP || ev.actionMasked == MotionEvent.ACTION_CANCEL) {
                routingSecondaryButtonGestureToGecko = false
            }
            if (routed) {
                return true
            }
            // The GeckoView child disappeared mid-gesture (session torn down,
            // fragment detaching). Nothing claimed it after all; let it fall
            // through to the ordinary path below rather than swallow it.
            routingSecondaryButtonGestureToGecko = false
        } else if (ev.actionMasked == MotionEvent.ACTION_DOWN && ev.isSecondaryMouseButton()) {
            // Only the secondary button is diverted to desktop semantics; the
            // primary button must keep flowing through touch dispatch below,
            // which BrowserHandlingScrollFeature and this layout's own nested
            // scrolling depend on.
            if (routeToGeckoMouseEvent(ev)) {
                routingSecondaryButtonGestureToGecko = true
                return true
            }
        }

        when (ev.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                // Against the previous stroke, before this one overwrites it.
                strokeIsZoomGesture = isSecondTapOfDoubleTap(ev)
                downX = ev.x
                downY = ev.y
                strokeHadMultiplePointers = false
            }

            MotionEvent.ACTION_POINTER_DOWN -> {
                strokeIsZoomGesture = true
                strokeHadMultiplePointers = true
            }

            MotionEvent.ACTION_UP -> {
                // A pinch is not the first tap of a double tap, so a stroke
                // that had a second pointer does not seed one.
                hasPreviousStroke = !strokeHadMultiplePointers
                previousDownX = downX
                previousDownY = downY
                previousUpTime = ev.eventTime
            }

            // A cancelled stroke never produced a tap either.
            MotionEvent.ACTION_CANCEL -> hasPreviousStroke = false
        }

        return super.dispatchTouchEvent(ev)
    }

    override fun onInterceptTouchEvent(event: MotionEvent): Boolean {
        // Setting "isEnabled = false" is how users of this ViewGroup turn pull
        // to refresh off; check it first so nothing below runs needlessly.
        if (!isEnabled || disallowInterceptTouchEvent || strokeIsZoomGesture) {
            return false
        }

        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                previousX = event.x
                previousY = event.y
            }

            MotionEvent.ACTION_MOVE -> {
                val xDistance = abs(event.x - previousX)
                val yDistance = abs(event.y - previousY)
                previousX = event.x
                previousY = event.y
                // Moving more on the X axis than on the Y axis is a sideways
                // swipe, not a pull.
                if (xDistance > yDistance) {
                    return false
                }
            }
        }

        return super.onInterceptTouchEvent(event)
    }

    override fun onStartNestedScroll(child: View, target: View, nestedScrollAxes: Int): Boolean {
        // Ignore nested scrolls from descendants. Honouring them would defeat
        // the filtering above and pull to refresh for every Y-axis movement
        // (scale gestures included), while doubling the throbber with the
        // overscroll shadow.
        return if (isEnabled) {
            false
        } else {
            super.onStartNestedScroll(child, target, nestedScrollAxes)
        }
    }

    override fun requestDisallowInterceptTouchEvent(disallowIntercept: Boolean) {
        // Record it for [onInterceptTouchEvent] but do not pass it up: the
        // parent may use the gesture for something else.
        disallowInterceptTouchEvent = disallowIntercept
    }

    /**
     * Hands [event] to the GeckoView child's `PanZoomController.onMouseEvent`,
     * which is what gives a secondary-button press desktop semantics — a
     * `contextmenu` event in the page — instead of the plain-touch handling
     * `onTouchEvent` gives every mouse button.
     *
     * Returns whether the event was actually handed off. `GeckoEngineView`
     * (this layout's first child, added in `BaseBrowserFragment`) wraps the
     * real `NestedGeckoView` as *its* first child — see
     * `BrowserHandlingScrollFeature.resolveTouchTargetView` for the same
     * precedent. If that child cannot be found, is not a [GeckoView], or has
     * no session attached yet, this returns `false` so the caller falls back
     * to the ordinary touch path instead of swallowing the event.
     */
    private fun routeToGeckoMouseEvent(event: MotionEvent): Boolean {
        val engineView = (getChildAt(0) as? ViewGroup)?.getChildAt(0) as? GeckoView ?: return false
        if (engineView.session == null) return false

        engineView.panZoomController.onMouseEvent(event)
        return true
    }

    /**
     * Whether `ev` is the second tap of a double tap, following
     * `GestureDetectorCompat#isConsideredDoubleTap`: the gap is measured from
     * the previous stroke's ACTION_UP, but the distance is measured between the
     * two ACTION_DOWNs.
     *
     * Comparing against where the previous stroke *ended* instead would call
     * any touch that lands near the end of a scroll or a pinch a double tap,
     * and silently suppress pull-to-refresh for it — a finger put back down
     * where it was lifted, which is exactly how a fling to the top of a page is
     * followed by a pull.
     */
    private fun isSecondTapOfDoubleTap(ev: MotionEvent): Boolean {
        if (!hasPreviousStroke) return false
        if (ev.eventTime - previousUpTime > doubleTapTimeoutMs) return false

        val dx = (ev.x - previousDownX).toLong()
        val dy = (ev.y - previousDownY).toLong()
        return dx * dx + dy * dy < doubleTapSlopSquare
    }
}
