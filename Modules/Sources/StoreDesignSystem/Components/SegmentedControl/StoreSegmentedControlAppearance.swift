import SwiftUI

/// The colors of a ``StoreSegmentedControl``, resolved for its enabled state.
struct StoreSegmentedControlAppearance: Equatable {
    let track: Color
    let selectedContainer: Color
    let selectedText: Color
    let unselectedText: Color

    init(isEnabled: Bool) {
        if isEnabled {
            track = .storeSecondaryContainer
            selectedContainer = .storeSurfaceBright
            selectedText = .storeOnSurface
            unselectedText = .storeOnPrimaryContainer
        } else {
            track = .storeStateLayerOnSurfaceOpacity08
            selectedContainer = .storeStateLayerOnSurfaceOpacity16
            selectedText = .storeStateLayerOnSurfaceOpacity24
            unselectedText = .storeStateLayerOnSurfaceOpacity24
        }
    }

    func text(isSelected: Bool) -> Color {
        isSelected ? selectedText : unselectedText
    }
}
