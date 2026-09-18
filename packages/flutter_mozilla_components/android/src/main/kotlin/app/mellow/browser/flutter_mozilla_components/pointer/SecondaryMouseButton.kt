/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package app.mellow.browser.flutter_mozilla_components.pointer

import android.view.InputDevice
import android.view.MotionEvent

/**
 * Whether this event is a secondary-button press from a mouse.
 *
 * GeckoView's `PanZoomController` has two entry points: `onTouchEvent`, which
 * treats every mouse button as a touch so a mouse can pan and zoom the page,
 * and `onMouseEvent`, whose own source comment says to call it "for behavior
 * similar to desktop" — that is what turns a secondary-button press into a
 * `contextmenu` event in the page. Only the secondary button needs that
 * treatment; the primary button must keep flowing through the ordinary touch
 * path, which `BrowserHandlingScrollFeature` and
 * [app.mellow.browser.flutter_mozilla_components.widget.ZoomAwareSwipeRefreshLayout]
 * depend on for nested scrolling and pull-to-refresh.
 *
 * The tool type is checked, not just the source: a stylus can report
 * [InputDevice.SOURCE_MOUSE] while hovering or with its barrel button held,
 * and that is not the input this exists to arbitrate.
 */
fun MotionEvent.isSecondaryMouseButton(): Boolean =
    source == InputDevice.SOURCE_MOUSE &&
        getToolType(0) !in STYLUS_TOOLS &&
        buttonState and MotionEvent.BUTTON_SECONDARY != 0

private val STYLUS_TOOLS = setOf(MotionEvent.TOOL_TYPE_STYLUS, MotionEvent.TOOL_TYPE_ERASER)
