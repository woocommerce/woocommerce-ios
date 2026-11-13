import SwiftUI

/// The colors of a ``StoreFilterChip``, resolved for its selected and enabled state.
/// The design defines no disabled variant, so the disabled colors follow the module's state-layer rule, as ``StoreButton`` does.
struct StoreFilterChipAppearance: Equatable {
    let background: Color
    let foreground: Color
    /// `nil` when the chip has no border (the selected, tonal chip).
    let border: Color?

    init(isSelected: Bool, isEnabled: Bool) {
        switch (isSelected, isEnabled) {
        case (false, true):
            background = .storeSurfaceBright
            foreground = .storeOnSurface
            border = .storeStateLayerOnSurfaceOpacity16
        case (false, false):
            background = .storeSurfaceBright
            foreground = .storeStateLayerOnSurfaceOpacity24
            border = .storeStateLayerOnSurfaceOpacity10
        case (true, true):
            background = .storeSecondaryContainer
            foreground = .storeOnSecondaryContainer
            border = nil
        case (true, false):
            background = .storeStateLayerOnSurfaceOpacity08
            foreground = .storeStateLayerOnSurfaceOpacity24
            border = nil
        }
    }
}
