import SwiftUI
import Combine

@Observable
public final class KeyboardObserver {
    public private(set) var isKeyboardVisible: Bool = false
    public private(set) var keyboardHeight: CGFloat = 0

    /// When an external keyboard is in use, iPadOS shows a quicktype bar at the bottom of the screen.
    /// This is reported as a keyboard with height, so `isKeyboardVisible` will be true and
    /// keyboard height will be > 0.
    /// However, it's much less of an impingement on the view, so there may be no modification to the view required.
    /// `isFullSizeKeyboardVisible` is true when the full software keyboard is shown.
    public var isFullSizeKeyboardVisible: Bool {
        return keyboardHeight > Constants.hardwareKeyboardHelperBarHeightThreshold
    }

    private var cancellables = Set<AnyCancellable>()

    public init() {
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

public extension KeyboardObserver {
    enum Constants {
        public static let hardwareKeyboardHelperBarHeightThreshold: CGFloat = 90
    }
}


private struct KeyboardObserverKey: EnvironmentKey {
    static var defaultValue: KeyboardObserver {
        KeyboardObserver()
    }
}

public extension EnvironmentValues {
    var keyboardObserver: KeyboardObserver {
        get { self[KeyboardObserverKey.self] }
        set { self[KeyboardObserverKey.self] = newValue }
    }
}

public struct KeyboardObserverProvider: ViewModifier {
    @State private var observer = KeyboardObserver()

    public func body(content: Content) -> some View {
        content.environment(\.keyboardObserver, observer)
    }
}

public extension View {
    func injectKeyboardObserver() -> some View {
        modifier(KeyboardObserverProvider())
    }
}
