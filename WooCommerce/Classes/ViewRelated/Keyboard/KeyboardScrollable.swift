import UIKit

/// Adjusts its scrollable view to accommodate the keyboard height.
protocol KeyboardScrollable {
    var scrollable: UIScrollView { get }

    func handleKeyboardFrameUpdate(keyboardFrame: CGRect)
}

extension KeyboardScrollable {
    func handleKeyboardFrameUpdate(keyboardFrame: CGRect) {
        let keyboardHeight = keyboardFrame.height
        scrollable.contentInset.bottom = keyboardHeight
        scrollable.scrollIndicatorInsets.bottom = keyboardHeight
    }
}
