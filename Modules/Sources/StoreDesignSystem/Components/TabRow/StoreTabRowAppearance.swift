import SwiftUI

/// The colors of a ``StoreTabRow``, resolved for its enabled state.
/// The design defines no disabled variant, so the disabled colors follow the module's state-layer rule, as ``StoreButton`` does.
struct StoreTabRowAppearance: Equatable {
    let background: Color
    let foreground: Color
    let indicator: Color

    init(isEnabled: Bool) {
        background = .storeSurfaceBright
        foreground = isEnabled ? .storeOnSurface : .storeStateLayerOnSurfaceOpacity24
        indicator = isEnabled ? .storePrimary : .storeStateLayerOnSurfaceOpacity24
    }
}
