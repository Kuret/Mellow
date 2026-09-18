/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package app.mellow.browser.flutter_mozilla_components.pointer

import android.view.InputDevice
import android.view.MotionEvent
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import org.junit.After
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, sdk = [28])
class SecondaryMouseButtonTest {
    private val retained = mutableListOf<MotionEvent>()

    @After
    fun tearDown() {
        retained.forEach { it.recycle() }
        retained.clear()
    }

    private fun event(
        source: Int,
        tool: Int,
        buttonState: Int,
    ): MotionEvent {
        val properties = MotionEvent.PointerProperties().apply { id = 0; toolType = tool }
        val coordinates = MotionEvent.PointerCoords().apply {
            x = 30f
            y = 40f
            pressure = 1f
        }
        return MotionEvent.obtain(
            100, 200, MotionEvent.ACTION_DOWN, 1, arrayOf(properties), arrayOf(coordinates),
            0, buttonState, 1f, 1f, 0, 0, source, 0,
        ).also { retained += it }
    }

    @Test
    fun rightButtonMouseIsSecondary() {
        assertTrue(
            event(InputDevice.SOURCE_MOUSE, MotionEvent.TOOL_TYPE_MOUSE, MotionEvent.BUTTON_SECONDARY)
                .isSecondaryMouseButton(),
        )
    }

    @Test
    fun leftButtonMouseIsNotSecondary() {
        assertFalse(
            event(InputDevice.SOURCE_MOUSE, MotionEvent.TOOL_TYPE_MOUSE, MotionEvent.BUTTON_PRIMARY)
                .isSecondaryMouseButton(),
        )
    }

    @Test
    fun fingerTouchIsNotSecondary() {
        // Fingers cannot report a button state at all, but the source alone
        // must already rule this out.
        assertFalse(
            event(InputDevice.SOURCE_TOUCHSCREEN, MotionEvent.TOOL_TYPE_FINGER, MotionEvent.BUTTON_SECONDARY)
                .isSecondaryMouseButton(),
        )
    }

    @Test
    fun stylusIsNotSecondary() {
        // A stylus barrel button reports SOURCE_MOUSE with BUTTON_SECONDARY
        // too, but it is not the mouse input this predicate arbitrates.
        assertFalse(
            event(InputDevice.SOURCE_MOUSE, MotionEvent.TOOL_TYPE_STYLUS, MotionEvent.BUTTON_SECONDARY)
                .isSecondaryMouseButton(),
        )
    }
}
