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

    /// Keep regular-width POS controls at the bottom edge. A full software keyboard
    /// must not move them, while the short external-keyboard helper bar still can.
    static func posBottomRegionsToIgnore(isCompact: Bool, isFullSizeKeyboardVisible: Bool) -> SafeAreaRegions {
        let container: SafeAreaRegions = isCompact ? [] : .container
        return isFullSizeKeyboardVisible ? container.union(.keyboard) : container
    }
}
