import SwiftUI
import Combine

@available(iOS 17.0, *)
@Observable
final class KeyboardObserver {
    private(set) var isKeyboardVisible: Bool = false
    private(set) var keyboardHeight: CGFloat = 0

    /// When an external keyboard is in use, iPadOS shows a quicktype bar at the bottom of the screen.
    /// This is reported as a keyboard with height, so `isKeyboardVisible` will be true and
    /// keyboard height will be > 0.
    /// However, it's much less of an impingement on the view, so there may be no modification to the view required.
    /// `isFullSizeKeyboardVisible` is true when the full software keyboard is shown.
    var isFullSizeKeyboardVisible: Bool {
        return keyboardHeight > Constants.hardwareKeyboardHelperBarHeightThreshold
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        NotificationCenter.Publisher(center: .default, name: UIResponder.keyboardWillShowNotification)
            .merge(with: NotificationCenter.Publisher(center: .default, name: UIResponder.keyboardDidShowNotification))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleKeyboardShow(notification: notification)
            }
            .store(in: &cancellables)

        NotificationCenter.Publisher(center: .default, name: UIResponder.keyboardWillHideNotification)
            .merge(with: NotificationCenter.Publisher(center: .default, name: UIResponder.keyboardDidHideNotification))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.keyboardHeight = 0
                self?.isKeyboardVisible = false
            }
            .store(in: &cancellables)
    }

    private func handleKeyboardShow(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        let keyboardFrame = frameValue.cgRectValue
        self.keyboardHeight = keyboardFrame.height
        self.isKeyboardVisible = true
    }
}

@available(iOS 17.0, *)
private extension KeyboardObserver {
    enum Constants {
        static let hardwareKeyboardHelperBarHeightThreshold: CGFloat = 90
    }
}


@available(iOS 17.0, *)
private struct KeyboardObserverKey: EnvironmentKey {
    static var defaultValue: KeyboardObserver {
        KeyboardObserver()
    }
}

@available(iOS 17.0, *)
extension EnvironmentValues {
    var keyboardObserver: KeyboardObserver {
        get { self[KeyboardObserverKey.self] }
        set { self[KeyboardObserverKey.self] = newValue }
    }
}

@available(iOS 17.0, *)
struct KeyboardObserverProvider: ViewModifier {
    @State private var observer = KeyboardObserver()

    func body(content: Content) -> some View {
        content.environment(\.keyboardObserver, observer)
    }
}

@available(iOS 17.0, *)
extension View {
    func injectKeyboardObserver() -> some View {
        modifier(KeyboardObserverProvider())
    }
}
