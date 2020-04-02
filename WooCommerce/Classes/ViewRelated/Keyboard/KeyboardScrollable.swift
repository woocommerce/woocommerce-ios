import UIKit

/// Adjusts its scrollable view to accommodate the keyboard height.
protocol KeyboardScrollable {
    var scrollable: UIScrollView { get }

    func handleKeyboardFrameUpdate(keyboardFrame: CGRect)
}

extension KeyboardScrollable where Self: UIViewController {
    func handleKeyboardFrameUpdate(keyboardFrame: CGRect) {
        let keyboardHeight = keyboardFrame.height

        let bottomInset: CGFloat = {
            // iPhone X+ adds a bottom inset for the Home Indicator. This inset is made irrelevant
            // if the keyboard is present. That's why we should deduct it from the final `bottomInset`
            // value. If we don't, the `scrollable` (i.e. TableView) will be shown with a space above
            // the keyboard.
            var inset = keyboardHeight - view.safeAreaInsets.bottom

            if let provider = self as? KeyboardFrameAdjustmentProvider {
                inset += provider.additionalKeyboardFrameHeight
            }

            return inset
        }()

        scrollable.contentInset.bottom = bottomInset
        scrollable.scrollIndicatorInsets.bottom = bottomInset
    }
}
