import SwiftUI

public extension Color {
    // MARK: - Interactive
    static let storeInteractivePrimary = bundledColor("storeInteractivePrimary")
    static let storeInteractiveDestructive = bundledColor("storeInteractiveDestructive")

    // MARK: - Primary
    static let storePrimaryPressed = bundledColor("storePrimaryPressed")

    // MARK: - Text
    static let storeTextPrimary = bundledColor("storeTextPrimary")
    static let storeTextSecondary = bundledColor("storeTextSecondary")
    static let storeTextTertiary = bundledColor("storeTextTertiary")
    static let storeTextDisabled = bundledColor("storeTextDisabled")
    static let storeTextOnPrimary = bundledColor("storeTextOnPrimary")

    // MARK: - Icon
    static let storeIconPrimary = bundledColor("storeIconPrimary")

    // MARK: - Surface
    static let storeSurfacePrimary = bundledColor("storeSurfacePrimary")
    static let storeSurfaceSecondary = bundledColor("storeSurfaceSecondary")
    static let storeSurfaceOverlay = bundledColor("storeSurfaceOverlay")

    // MARK: - Border
    static let storeBorderDefault = bundledColor("storeBorderDefault")
    static let storeBorderFocused = bundledColor("storeBorderFocused")

    // MARK: - Status
    static let storeStatusSuccess = bundledColor("storeStatusSuccess")
    static let storeStatusError = bundledColor("storeStatusError")
    static let storeStatusWarning = bundledColor("storeStatusWarning")

    // MARK: - Label
    static let storeLabelPrimary = bundledColor("storeLabelPrimary")
    static let storeLabelSecondary = bundledColor("storeLabelSecondary")
    static let storeLabelTertiary = bundledColor("storeLabelTertiary")
    static let storeLabelDisabled = bundledColor("storeLabelDisabled")
    static let storeLabelOnPrimary = bundledColor("storeLabelOnPrimary")

    /// Loads a named color from the design system's asset catalog in this package's bundle.
    private static func bundledColor(_ name: String) -> Color {
        Color(name, bundle: .module)
    }
}
