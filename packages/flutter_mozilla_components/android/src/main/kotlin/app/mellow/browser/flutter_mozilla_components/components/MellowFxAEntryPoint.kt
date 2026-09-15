package app.mellow.browser.flutter_mozilla_components.components

import mozilla.components.concept.sync.FxAEntryPoint

enum class MellowFxAEntryPoint(override val entryName: String) : FxAEntryPoint {
    Settings("settings"),
}
