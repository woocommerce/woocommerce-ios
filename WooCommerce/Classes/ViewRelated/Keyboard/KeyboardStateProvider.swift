
import UIKit

struct KeyboardState {
    let isVisible: Bool
    let frameEnd: CGRect
}

protocol KeyboardStateProviding {
    var state: KeyboardState { get }
}

final class KeyboardStateProvider: KeyboardStateProviding {
    private(set) var state: KeyboardState = KeyboardState(isVisible: false, frameEnd: .zero)

    private var observations = [Any]()

    init() {
        let nc = NotificationCenter.default

        observations.append(
            nc.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: nil) { [weak self] notification in
                self?.updateState(from: notification)
            }
        )
        observations.append(
            nc.addObserver(forName: UIResponder.keyboardDidHideNotification, object: nil, queue: nil) { [weak self] notification in
                self?.updateState(from: notification)
            }
        )
    }

    private func updateState(from notification: Notification) {
        state = KeyboardState(
            isVisible: notification.name == UIResponder.keyboardDidShowNotification,
            frameEnd: notification.keyboardFrameEnd ?? .zero
        )
    }

    deinit {
        observations.forEach(NotificationCenter.default.removeObserver)
    }
}

private extension Notification {
    var keyboardFrameEnd: CGRect? {
        guard let rectAsValue = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return nil
        }

        return rectAsValue.cgRectValue
    }
}

