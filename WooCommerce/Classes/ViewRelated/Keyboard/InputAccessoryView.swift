import UIKit

/// Allows a text input's `inputAccessoryView` to use Auto Layout subviews above the keyboard.
/// The main view can be added to its subview, and pins to its edges.
///
final class InputAccessoryView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        // Required to make the view grow vertically.
        autoresizingMask = .flexibleHeight
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        // Calculates intrinsic content size that fits to content.
        let contentSize = sizeThatFits(CGSize(width: bounds.width, height: .greatestFiniteMagnitude))
        return CGSize(width: bounds.width, height: contentSize.height)
    }
}
