import SwiftUI
import Combine

final class KeyboardObserver: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    private var cancellables = Set<AnyCancellable>()

    init() {
        observeKeyboardNotifications()
    }

    private func observeKeyboardNotifications() {
        let keyboardWillChange = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
        let keyboardWillHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)

        keyboardWillChange
            .merge(with: keyboardWillHide)
            .sink { [weak self] notification in
                self?.handleKeyboardNotification(notification)
            }
            .store(in: &cancellables)
    }

    private func handleKeyboardNotification(_ notification: Notification) {
        // UIResponder.keyboardFrameEndUserInfoKey contains where the keyboard will be after the animation completes,
        // so we know the keyboard's end position in the screen
        guard let userInfo = notification.userInfo,
              let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let screenHeight = UIScreen.main.bounds.height
        keyboardHeight = (endFrame.origin.y >= screenHeight) ? 0 : endFrame.height
    }
}
