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
