import SwiftUI

extension SafeAreaRegions {
    /// Preserve the iOS 26+ regular-width bottom inset workaround. A full software keyboard
    /// must not move them, while the short external-keyboard helper bar still can.
    static func posBottomRegionsToIgnore(isCompact: Bool, isFullSizeKeyboardVisible: Bool) -> SafeAreaRegions {
        var container: SafeAreaRegions = []
        if !isCompact, #available(iOS 26, *) {
            container = .container
        }
        return isFullSizeKeyboardVisible ? container.union(.keyboard) : container
    }
}
