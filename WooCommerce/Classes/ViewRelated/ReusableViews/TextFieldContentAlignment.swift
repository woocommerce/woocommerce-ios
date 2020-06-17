import UIKit

/// Horizontal alignment for content (text or placeholder) in a text field.
enum TextFieldContentAlignment {
    case leading
    case trailing
    case center
}

extension TextFieldContentAlignment {
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
