import UIKit

/// Observes the keyboard frame and notifies its subscriber.
final class KeyboardFrameObserver {
    private let onKeyboardFrameUpdate: OnKeyboardFrameUpdate

    /// Notifies the closure owner about any keyboard frame change.
    /// Note that the frame is based on the keyboard window coordinate.
    typealias OnKeyboardFrameUpdate = (_ keyboardFrame: CGRect) -> Void

    private let notificationCenter: NotificationCenter

    private var keyboardFrame: CGRect? {
        didSet {
            if let keyboardFrame = keyboardFrame, oldValue != keyboardFrame {
                onKeyboardFrameUpdate(keyboardFrame)
            }
        }
    }

    init(notificationCenter: NotificationCenter = NotificationCenter.default,
         onKeyboardFrameUpdate: @escaping OnKeyboardFrameUpdate) {
        self.notificationCenter = notificationCenter
        self.onKeyboardFrameUpdate = onKeyboardFrameUpdate
    }

    func startObservingKeyboardFrame() {
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

private extension KeyboardFrameObserver {
    @objc func keyboardWillShow(_ notification: Foundation.Notification) {
        guard let keyboardFrame = keyboardRect(from: notification) else {
            return
        }
        self.keyboardFrame = keyboardFrame
    }

    @objc func keyboardWillHide(_ notification: Foundation.Notification) {
        guard let keyboardFrame = keyboardRect(from: notification) else {
            return
        }
        self.keyboardFrame = keyboardFrame
    }
}

private extension KeyboardFrameObserver {
    /// Returns the Keyboard Rect from a Keyboard Notification.
    ///
    func keyboardRect(from note: Notification) -> CGRect? {
        let wrappedRect = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        return wrappedRect?.cgRectValue
    }
}
