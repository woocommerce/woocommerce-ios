import SwiftUI

extension View {
    /// Standard bottom-action padding for phone POS full-screen flows.
    func posPhoneBottomButtonPadding(bottom: CGFloat = POSPadding.medium) -> some View {
        padding(.horizontal, POSPadding.medium)
            .padding(.top, POSPadding.medium)
            .padding(.bottom, bottom)
    }
}

enum POSCompactFooterLayout {
    /// Match the compact page header's top spacing when there is no bottom inset.
    /// The system safe area supplies that space when its inset is larger.
    static func bottomPadding(safeAreaInset: CGFloat) -> CGFloat {
        max(POSPadding.medium - safeAreaInset, POSPadding.none)
    }
}
