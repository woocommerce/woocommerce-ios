import SwiftUI

/// The colors of a ``StoreCell``, resolved for its enabled state.
/// The design defines no disabled variant, so the disabled colors follow the module's state-layer rule, as ``StoreButton`` does.
struct StoreCellAppearance: Equatable {
    let background: Color
    let title: Color
    let description: Color
    /// The tint applied to the leading / trailing slots and the disclosure indicator.
    let slot: Color

    init(isEnabled: Bool) {
        background = .storeSurfaceBright
        if isEnabled {
            title = .storeOnSurface
            description = .storeOnSurfaceVariant
            slot = .storeOnSurfaceVariant
        } else {
            title = .storeStateLayerOnSurfaceOpacity24
            description = .storeStateLayerOnSurfaceOpacity24
            slot = .storeStateLayerOnSurfaceOpacity24
        }
    }
}
