/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package app.mellow.browser.flutter_mozilla_components.components

import app.mellow.browser.flutter_mozilla_components.feature.ReadabilityExtractFeature
import app.mellow.browser.flutter_mozilla_components.feature.WebExtensionToolbarFeature
import app.mellow.browser.flutter_mozilla_components.feature.WebInspectorFeature
import app.mellow.browser.flutter_mozilla_components.pigeons.GeckoAddonEvents
import app.mellow.browser.flutter_mozilla_components.pigeons.GeckoTabContentEvents
import mozilla.components.browser.state.store.BrowserStore
import mozilla.components.concept.engine.Engine

class Features(
    private val engine: Engine,
    private val store: BrowserStore,
    private val addonEvents: GeckoAddonEvents,
    private var tabContentEvents: GeckoTabContentEvents
) {
    val webExtensionToolbarFeature by lazy {
        WebExtensionToolbarFeature(
            store,
            addonEvents
        )
    }

    val readabilityExtractFeature by lazy {
        ReadabilityExtractFeature(
            engine,
            store,
            tabContentEvents
        )
    }

    val webInspectorFeature by lazy {
        WebInspectorFeature(
            engine,
            store
        )
    }
}