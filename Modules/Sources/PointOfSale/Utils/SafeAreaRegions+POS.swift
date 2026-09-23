import SwiftUI

extension SafeAreaRegions {
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
