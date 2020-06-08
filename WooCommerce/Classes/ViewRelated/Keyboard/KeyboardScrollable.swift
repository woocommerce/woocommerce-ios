import UIKit

/// Adjusts its scrollable view to accommodate the keyboard height.
protocol KeyboardScrollable {
    var scrollable: UIScrollView { get }

    func handleKeyboardFrameUpdate(keyboardFrame: CGRect)
}

extension KeyboardScrollable where Self: UIViewController {
    func handleKeyboardFrameUpdate(keyboardFrame: CGRect) {
        let keyboardHeight = keyboardFrame.height

        let bottomInsetFromSafeArea: CGFloat

        switch scrollable.contentInsetAdjustmentBehavior {
        case .never where keyboardHeight == 0:
            // If the `contentInset` is not meant to be adjusted, there should be zero inset from the safe area when the keyboard height is zero.
            bottomInsetFromSafeArea = 0
        default:
            // iPhone X+ adds a bottom inset for the Home Indicator. This inset is made irrelevant
            // if the keyboard is present. That's why we should deduct it from the final `bottomInset`
            // value. If we don't, the `scrollable` (i.e. TableView) will be shown with a space above
            // the keyboard.
            var inset = -view.safeAreaInsets.bottom

            if let provider = self as? KeyboardFrameAdjustmentProvider {
                inset += provider.additionalKeyboardFrameHeight
            }

            bottomInsetFromSafeArea = inset
        }

        let bottomInset = keyboardHeight + bottomInsetFromSafeArea

        scrollable.contentInset.bottom = bottomInset
        scrollable.scrollIndicatorInsets.bottom = bottomInset
    }
}
