import SwiftUI

extension SafeAreaRegions {
    /// iOS 26 NavigationStack introduces container insets that shift content.
    /// Keep the workaround on iOS 26, then use the system safe area on iOS 27+.
    static var posContainerRegionToIgnore: SafeAreaRegions {
        if #available(iOS 27, *) {
            return []
        }
        if #available(iOS 26, *) {
            return .container
        }
        return []
    }

    /// Full-screen foregrounds used to extend under system UI. On iOS 27+ the
    /// safe area can also describe a vertical bar, so only backgrounds extend.
    static var posFullScreenForegroundRegionToIgnore: SafeAreaRegions {
        if #available(iOS 27, *) {
            return []
        }
        return .all
    }

    /// Preserve views that always ignored the container before iOS 27.
    static var posLegacyContainerRegionToIgnore: SafeAreaRegions {
        if #available(iOS 27, *) {
            return []
        }
        return .container
    }
}
