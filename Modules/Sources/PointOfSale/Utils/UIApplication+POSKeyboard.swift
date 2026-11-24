import UIKit

extension UIApplication {
    /// Ends editing at once, before the caller changes what is on screen.
    ///
    /// Clearing a `@FocusState` only takes effect on a later update. If the screen changes in the
    /// same update, UIKit moves the text field while it is still first responder and gives it the
    /// keyboard back the next time the field is moved, for example when a modal is presented.
    func posDismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func posDismissSearchKeyboardOnResultSelection(isCompactLayout: Bool) {
        guard POSSearchViewHelper.dismissesKeyboardOnResultSelection(isCompactLayout: isCompactLayout) else {
            return
        }
        posDismissKeyboard()
    }
}
