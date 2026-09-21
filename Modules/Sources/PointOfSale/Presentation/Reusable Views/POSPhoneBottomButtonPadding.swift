import SwiftUI

extension View {
    /// Standard bottom-action padding for phone POS full-screen flows.
    func posPhoneBottomButtonPadding() -> some View {
        padding(.horizontal, POSPhoneBottomButtonPadding.horizontal)
            .padding(.top, POSPhoneBottomButtonPadding.top)
            .padding(.bottom, POSPhoneBottomButtonPadding.bottom)
    }
}

private enum POSPhoneBottomButtonPadding {
    static let horizontal: CGFloat = POSPadding.medium
    static let top: CGFloat = POSPadding.medium
    static let bottom: CGFloat = POSPadding.xxLarge
}
