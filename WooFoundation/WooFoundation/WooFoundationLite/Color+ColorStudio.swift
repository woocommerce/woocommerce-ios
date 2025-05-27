import SwiftUI

public extension Color {
    /// Get a Color from the Color Studio color palette
    ///
    /// - Parameters:
    ///   - color: an instance of a ColorStudio
    /// - Returns: Color. Red in cases of error
    static func withColorStudio(name: ColorStudioName, shade: ColorStudioShade) -> Color {
        let assetName = ColorStudio(name: name, shade: shade).assetName()
        return Color(assetName, bundle: Bundle(for: WooFoundationBundleClass.self))
    }
}
