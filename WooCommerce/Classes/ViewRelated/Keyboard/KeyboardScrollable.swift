import UIKit

/// Adjusts its scrollable view to accommodate the keyboard height.
protocol KeyboardScrollable {
    var scrollable: UIScrollView { get }

    func handleKeyboardFrameUpdate(keyboardFrame: CGRect)
}

extension KeyboardScrollable where Self: UIViewController {
    func handleKeyboardFrameUpdate(keyboardFrame: CGRect) {
        let keyboardHeight = keyboardFrame.height

        // iPhone X+ adds a bottom inset for the Home Indicator. This inset is made irrelevant
        // if the keyboard is present. That's why we should deduct it from the final `bottomInset`
        // value. If we don't, the `scrollable` (i.e. TableView) will be shown with a space above
        // the keyboard.
        let bottomInset = keyboardHeight - view.safeAreaInsets.bottom

        scrollable.contentInset.bottom = bottomInset
        scrollable.scrollIndicatorInsets.bottom = bottomInset
    }
}
