/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package app.mellow.browser.flutter_mozilla_components.pointer

import app.mellow.browser.flutter_mozilla_components.pigeons.PointerHitTest
import app.mellow.browser.flutter_mozilla_components.pigeons.PointerInputFlutterApi
import io.flutter.plugin.common.BinaryMessenger

/**
 * What [PointerInputRouter] needs from the Dart half.
 *
 * Behind an interface because the router's whole reason to exist is that these
 * answers are asynchronous: its tests have to be able to answer out of order,
 * late, or not at all, which a live channel cannot be made to do.
 */
internal interface PointerInputHost {
    /**
     * Asks which surface owns [x]/[y], in physical pixels local to the Flutter
     * view. Answers `null` when Dart could not be reached at all, which the
     * router must never read as "Flutter owns it".
     */
    fun hitTest(x: Double, y: Double, tracksHover: Boolean, onResult: (PointerHitTest?) -> Unit)

    /** Tells Dart the cursor left every registered surface. */
    fun pointerExit()

    /**
     * Tells Dart a secondary mouse button went down at [x]/[y], in physical
     * pixels local to the Flutter view. Reported only; the engine still gets
     * the event.
     */
    fun secondaryButtonDown(x: Double, y: Double)

    /**
     * Tells Dart a finger long-press landed at [x]/[y], in physical pixels
     * local to the Flutter view. Reported only; the engine still gets the
     * touch.
     */
    fun longPress(x: Double, y: Double)

    /**
     * Tells Dart a finger touched down at [x]/[y], in physical pixels local
     * to the Flutter view. Reported only; the engine still gets the touch.
     */
    fun touchDown(x: Double, y: Double)
}

/** The production host: the generated pigeon channel. */
internal class PigeonPointerInputHost(messenger: BinaryMessenger) : PointerInputHost {
    private val api = PointerInputFlutterApi(messenger)

    override fun hitTest(
        x: Double,
        y: Double,
        tracksHover: Boolean,
        onResult: (PointerHitTest?) -> Unit,
    ) {
        // A messenger whose engine is going away throws rather than calling
        // back, and the retained event still has to reach somebody.
        try {
            api.hitTest(x, y, tracksHover) { onResult(it.getOrNull()) }
        } catch (_: RuntimeException) {
            onResult(null)
        }
    }

    override fun pointerExit() {
        try {
            api.pointerExit {}
        } catch (_: RuntimeException) {
            // Nothing to recover: Dart's hover watch stops with its isolate.
        }
    }

    override fun secondaryButtonDown(x: Double, y: Double) {
        try {
            api.secondaryButtonDown(x, y) {}
        } catch (_: RuntimeException) {
            // A click nobody is left to answer needs no menu.
        }
    }

    override fun longPress(x: Double, y: Double) {
        try {
            api.longPress(x, y) {}
        } catch (_: RuntimeException) {
            // A press nobody is left to answer needs no menu.
        }
    }

    override fun touchDown(x: Double, y: Double) {
        try {
            api.touchDown(x, y) {}
        } catch (_: RuntimeException) {
            // Nobody left to anchor a menu for.
        }
    }
}
