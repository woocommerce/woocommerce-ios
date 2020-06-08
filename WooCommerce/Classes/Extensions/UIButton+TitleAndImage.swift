import UIKit

extension UIButton {
    /// Sets a spacing between button title and image.
    /// - Parameters:
    ///   - spacing: spacing between the title and image.
    ///   - layoutDirection: layout direction of the button (LTR/RTL).
    func distributeTitleAndImage(spacing: CGFloat, layoutDirection: UIUserInterfaceLayoutDirection = UIApplication.shared.userInterfaceLayoutDirection) {
        let insetAmount = spacing / 2.0

        switch layoutDirection {
        case .rightToLeft:
            imageEdgeInsets = UIEdgeInsets(top: imageEdgeInsets.top, left: insetAmount, bottom: imageEdgeInsets.bottom, right: imageEdgeInsets.right)
            titleEdgeInsets = UIEdgeInsets(top: titleEdgeInsets.top, left: titleEdgeInsets.left, bottom: titleEdgeInsets.bottom, right: insetAmount)
        default:
            imageEdgeInsets = UIEdgeInsets(top: imageEdgeInsets.top, left: imageEdgeInsets.left, bottom: imageEdgeInsets.bottom, right: insetAmount)
            titleEdgeInsets = UIEdgeInsets(top: titleEdgeInsets.top, left: insetAmount, bottom: titleEdgeInsets.bottom, right: titleEdgeInsets.right)
        }
    }
}
