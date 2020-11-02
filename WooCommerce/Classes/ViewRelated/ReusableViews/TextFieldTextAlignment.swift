import UIKit

/// How the text content (text or placeholder) is aligned horizontally in a `UITextField`.
/// Since `NSTextAlignment` does not have .leading and .trailing cases for .left and .right respectively, this enum is used as a wrapper for specifying
/// `NSTextAlignment` for a `UITextField` with the layout direction in mind.
enum TextFieldTextAlignment {
    case leading
    case trailing
    case center
}

extension TextFieldTextAlignment {
    func toTextAlignment(layoutDirection: UIUserInterfaceLayoutDirection = UIApplication.shared.userInterfaceLayoutDirection) -> NSTextAlignment {
        let isLeftToRight = layoutDirection == .leftToRight
        switch self {
        case .leading:
            return isLeftToRight ? .left: .right
        case .trailing:
            return isLeftToRight ? .right: .left
        case .center:
            return .center
        }
    }
}
