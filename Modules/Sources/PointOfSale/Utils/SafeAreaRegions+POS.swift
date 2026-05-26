import SwiftUI

extension SafeAreaRegions {
    /// iOS 26 NavigationStack introduces container insets that shift content.
    /// Use this to ignore `.container` only on iOS 26+.
    static var posContainerRegionToIgnore: SafeAreaRegions {
        if #available(iOS 26, *) {
            return .container
        } else {
            return []
        }
    }
}
