import SwiftUI

/// The colors of a ``StoreTopAppBar``, resolved for its enabled state.
///
/// - Note: The design defines one container (surface bright) and no disabled variant, so the
///   disabled presentation follows the module's uniform state-layer rule (as ``StoreCell`` does).
struct StoreTopAppBarAppearance: Equatable {
    let background: Color
    let title: Color
    let supportingText: Color
    /// The tint of the navigation control and the action icons.
    let control: Color

    init(isEnabled: Bool) {
        background = .storeSurfaceBright
        if isEnabled {
            title = .storeOnSurface
            supportingText = .storeOnSurfaceVariantLowest
            control = .storeOnSurface
        } else {
            title = .storeStateLayerOnSurfaceOpacity24
            supportingText = .storeStateLayerOnSurfaceOpacity24
            control = .storeStateLayerOnSurfaceOpacity24
        }
    }
}
