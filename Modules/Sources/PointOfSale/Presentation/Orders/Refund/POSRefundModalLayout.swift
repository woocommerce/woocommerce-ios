import Foundation
import SwiftUI

enum POSRefundModalLayout {
    static let horizontalPadding: CGFloat = 148
    static let cornerRadius: CGFloat = POSCornerRadiusStyle.extraLarge.value
    static let progressViewStyle = POSProgressViewStyle(size: 64, lineWidth: 20)

    /// Phone uses 0 horizontal padding so the modal can fill the narrow screen instead of
    /// shrinking the content to a thin strip with the iPad-tuned 148pt insets.
    static func horizontalPadding(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .compact ? 0 : horizontalPadding
    }

    /// Phone presents the modal full-screen via `posModalFullScreen`, so the inner card
    /// should not be rounded (otherwise an inner-rounded card sits inside a square
    /// full-screen modal). On iPad the iPad-tuned corner radius is applied.
    static func cornerRadius(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .compact ? 0 : cornerRadius
    }
}

/// Sizes a refund-flow modal: a centered, rounded card on iPad; an edge-to-edge full
/// screen take-over on phone. Matches the rest of the phone-prototype UI where modal
/// flows occupy the entire screen rather than appearing as a partial sheet.
struct POSRefundModalFrameModifier: ViewModifier {
    let parentSize: CGSize
    let horizontalSizeClass: UserInterfaceSizeClass?

    func body(content: Content) -> some View {
        if horizontalSizeClass == .compact {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            content
                .clipShape(RoundedRectangle(cornerRadius: POSRefundModalLayout.cornerRadius))
                .frame(width: parentSize.width - (POSRefundModalLayout.horizontalPadding(for: horizontalSizeClass) * 2))
        }
    }
}

extension View {
    func posRefundModalFrame(parentSize: CGSize, horizontalSizeClass: UserInterfaceSizeClass?) -> some View {
        modifier(POSRefundModalFrameModifier(parentSize: parentSize, horizontalSizeClass: horizontalSizeClass))
    }
}

/// Standardizes the bottom-anchored action buttons across the phone POS so refund / totals /
/// cart all share the same horizontal insets and home-indicator clearance as the phone cart
/// button. iPad keeps the existing in-card padding so the centered modal still breathes.
struct POSPhoneFullScreenButtonPaddingModifier: ViewModifier {
    let horizontalSizeClass: UserInterfaceSizeClass?

    func body(content: Content) -> some View {
        if horizontalSizeClass == .compact {
            content
                .padding(.horizontal, POSPadding.medium)
                .padding(.top, POSPadding.medium)
                .padding(.bottom, POSPadding.xxLarge)
        } else {
            content
                .padding(POSPadding.xLarge)
        }
    }
}

extension View {
    func posPhoneFullScreenButtonPadding(horizontalSizeClass: UserInterfaceSizeClass?) -> some View {
        modifier(POSPhoneFullScreenButtonPaddingModifier(horizontalSizeClass: horizontalSizeClass))
    }
}
