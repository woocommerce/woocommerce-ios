import SwiftUI

/// POS Background Appearance can be primary or secondary (light or dark) depending on the context.
/// Some elements that appear on top of the POS need to be informed of background state to change its appearance.
///
enum POSBackgroundAppearanceKey: EnvironmentKey {
    enum Appearance {
        case primary
        case secondary
    }

    static let defaultValue = Appearance.primary
}

extension EnvironmentValues {
    var posBackgroundAppearance: POSBackgroundAppearanceKey.Appearance {
        get { self[POSBackgroundAppearanceKey.self] }
        set { self[POSBackgroundAppearanceKey.self] = newValue }
    }
}
