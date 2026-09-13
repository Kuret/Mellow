/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package eu.weblibre.flutter_mozilla_components.api

import eu.weblibre.flutter_mozilla_components.GlobalComponents
import eu.weblibre.flutter_mozilla_components.pigeons.GeckoWebInspectorApi

/**
 * Implementation of GeckoWebInspectorApi, forwarding to the web inspector
 * extension through [eu.weblibre.flutter_mozilla_components.feature.WebInspectorFeature].
 */
class GeckoWebInspectorApiImpl : GeckoWebInspectorApi {
    private val components by lazy {
        requireNotNull(GlobalComponents.components) { "Components not initialized" }
    }

    override fun showInspector(tabId: String?, panel: String?) {
        components.features.webInspectorFeature.send(tabId, "show", panel)
    }

    override fun hideInspector(tabId: String?) {
        components.features.webInspectorFeature.send(tabId, "hide")
    }

    override fun pickElement(tabId: String?) {
        components.features.webInspectorFeature.send(tabId, "pick")
    }
}
