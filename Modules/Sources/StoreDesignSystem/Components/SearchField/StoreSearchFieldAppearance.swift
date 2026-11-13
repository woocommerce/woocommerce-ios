import SwiftUI

/// The colors of a ``StoreSearchField``, resolved for its enabled state.
///
/// - Note: The design defines one container (surface bright), one field fill (surface dim) and no
///   disabled variant, so the disabled presentation follows the module's state-layer rule, as
///   ``StoreFilterChip`` and ``StoreTopAppBar`` do: the fills stay, the content dims.
struct StoreSearchFieldAppearance: Equatable {
    let container: Color
    let field: Color
    /// The entered text, the magnifying glass and the clear control.
    let content: Color
    let placeholder: Color
    /// The trailing text action.
    let action: Color

    init(isEnabled: Bool) {
        container = .storeSurfaceBright
        field = .storeSurfaceDim
        placeholder = .storeStateLayerOnSurfaceOpacity24
        if isEnabled {
            content = .storeOnSurface
            action = .storePrimary
        } else {
            content = .storeStateLayerOnSurfaceOpacity24
            action = .storeStateLayerOnSurfaceOpacity24
        }
    }
}
