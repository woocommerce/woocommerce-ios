import UIKit

/// Observes the keyboard frame and notifies its subscriber.
struct KeyboardFrameObserver {
    private let onKeyboardFrameUpdate: OnKeyboardFrameUpdate

    private let keyboardStateProvider: KeyboardStateProviding

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
         keyboardStateProvider: KeyboardStateProviding = ServiceLocator.keyboardStateProvider,
         onKeyboardFrameUpdate: @escaping OnKeyboardFrameUpdate) {
        self.notificationCenter = notificationCenter
        self.keyboardStateProvider = keyboardStateProvider
        self.onKeyboardFrameUpdate = onKeyboardFrameUpdate
    }

    mutating func startObservingKeyboardFrame(sendInitialEvent: Bool = false) {
        var observer = self
        notificationCenter.addObserver(forName: UIResponder.keyboardWillShowNotification,
                                       object: nil,
                                       queue: nil) { notification in
                                        observer.keyboardWillShow(notification)
        }

        notificationCenter.addObserver(forName: UIResponder.keyboardWillHideNotification,
                                       object: nil,
                                       queue: nil) { notification in
                                        observer.keyboardWillHide(notification)
        }

        if sendInitialEvent {
            keyboardFrame = keyboardStateProvider.state.frameEnd
        }
    }
}

private extension KeyboardFrameObserver {
    mutating func keyboardWillShow(_ notification: Foundation.Notification) {
        guard let keyboardFrame = keyboardRect(from: notification) else {
            return
        }
        self.keyboardFrame = keyboardFrame
    }

    mutating func keyboardWillHide(_ notification: Foundation.Notification) {
        self.keyboardFrame = .zero
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
