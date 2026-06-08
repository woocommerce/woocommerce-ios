import SwiftUI

extension View {
    /// Standard bottom-action padding for compact POS full-screen flows.
    func posCompactBottomButtonPadding() -> some View {
        padding(.horizontal, POSCompactBottomButtonPadding.horizontal)
            .padding(.top, POSCompactBottomButtonPadding.top)
            .padding(.bottom, POSCompactBottomButtonPadding.bottom)
    }
}

private enum POSCompactBottomButtonPadding {
    static let horizontal: CGFloat = POSPadding.medium
    static let top: CGFloat = POSPadding.medium
    static let bottom: CGFloat = POSPadding.xxLarge
}
