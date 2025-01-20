import SwiftUI
import Combine

final class KeyboardObserver: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    private var cancellables = Set<AnyCancellable>()

    init() {
        let keyboardWillShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
        let keyboardWillHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)

        keyboardWillShow.merge(with: keyboardWillHide)
            .sink { [weak self] notification in
                guard let self = self else { return }
                if let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    self.keyboardHeight = endFrame.origin.y >= UIScreen.main.bounds.height ? 0 : endFrame.height
                }
            }
            .store(in: &cancellables)
    }
}
