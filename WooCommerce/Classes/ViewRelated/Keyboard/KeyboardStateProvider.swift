
import UIKit

enum KeyboardState {
    case hidden
    case shown
}

protocol KeyboardStateProviding {
    var state: KeyboardState { get }
}

final class KeyboardStateProvider: KeyboardStateProviding {
    private(set) var state: KeyboardState = .hidden

    private var observations = [Any]()

    init() {
        let nc = NotificationCenter.default

        observations.append(
            nc.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: nil) { [weak self] _ in
                self?.state = .shown
            }
        )
        observations.append(
            nc.addObserver(forName: UIResponder.keyboardDidHideNotification, object: nil, queue: nil) { [weak self] _ in
                self?.state = .hidden
            }
        )
    }

    deinit {
        observations.forEach(NotificationCenter.default.removeObserver)
    }
}

