import SwiftUI

/// The colors of a ``StoreCell``, resolved for its enabled state.
///
/// - Note: The design defines one container (surface bright) and no disabled variant, so the
///   disabled presentation follows the module's uniform state-layer rule (as ``StoreButton`` does)
///   rather than a cell-specific token.
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

/// How a non-interactive ``StoreCell`` groups its children for VoiceOver.
enum StoreCellAccessibility {
    /// A cell whose trailing slot is empty reads as one element (title, description). A populated
    /// trailing slot may hold its own control (e.g. a toggle), so the children stay reachable.
    static func childBehavior(hasTrailingContent: Bool) -> AccessibilityChildBehavior {
        hasTrailingContent ? .contain : .combine
    }
}
