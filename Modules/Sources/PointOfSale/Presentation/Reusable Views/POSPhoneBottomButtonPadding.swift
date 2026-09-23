import SwiftUI

extension View {
    /// Standard bottom-action padding for phone POS full-screen flows.
    func posPhoneBottomButtonPadding(bottom: CGFloat = POSPhoneBottomButtonPadding.bottom) -> some View {
        padding(.horizontal, POSPhoneBottomButtonPadding.horizontal)
            .padding(.top, POSPhoneBottomButtonPadding.top)
            .padding(.bottom, bottom)
    }
}

private enum POSPhoneBottomButtonPadding {
    static let horizontal: CGFloat = POSPadding.medium
    static let top: CGFloat = POSPadding.medium
    static let bottom: CGFloat = POSPadding.medium
}

enum POSCompactFooterLayout {
    /// Match the compact page header's top spacing when there is no bottom inset.
    /// The system safe area supplies that space when its inset is larger.
    static func bottomPadding(safeAreaInset: CGFloat) -> CGFloat {
        max(POSPadding.medium - safeAreaInset, POSPadding.none)
    }
}
