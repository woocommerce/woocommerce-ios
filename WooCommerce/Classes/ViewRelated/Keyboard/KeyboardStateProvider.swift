
import UIKit

/// Keyboard information usually received from `Notifications`.
///
struct KeyboardState: Equatable {
    /// True if the keyboard is visible.
    let isVisible: Bool
    /// The frame of the keyboard when it is fully shown or hidden.
    ///
    /// The value is from `UIResponder.keyboardFrameEndUserInfoKey`.
    ///
    /// Note that even if `isVisible` is `false`, this can still have a **non-zero** value. This
    /// can happen in this scenario:
    ///
    /// 1. View-A is shown and the keyboard is shown.
    /// 2. User taps on something which presents View-B **while** the keyboard is present.
    ///    View-B does not have a user responder (text field) so the keyboard is not visible.
    /// 3. NSNotificationCenter emits a `keyboardDidHideNotification` but with a
    ///    `keyboardFrameEndUserInfoKey` value set to the **previously shown keyboard's frame**.
    ///
    let frameEnd: CGRect
}

/// Provides the last known state of the keyboard.
///
protocol KeyboardStateProviding {
    /// The last known state of the keyboard.
    var state: KeyboardState { get }
}

/// Provides and tracks the last known state of the keyboard.
///
/// This does not work very well as a one-off instance. It has to be instantiated and **kept**
/// when the app is started (i.e. `UIApplicationDelegate`) so it can _track_ the keyboard changes.
/// Only then will this be able to accurately provide the last known state of the keyboard.
///
/// Initially, this assumes that the keyboard is not visible.
///
final class KeyboardStateProvider: KeyboardStateProviding {
    /// The NotificationCenter to observe
    private let notificationCenter: NotificationCenter

    /// The last known state.
    ///
    /// This is kept up to date whenever we receive keyboard notifications.
    ///
    private(set) var state: KeyboardState = KeyboardState(isVisible: false, frameEnd: .zero)

    /// NSNotification observers that will be removed on deinit
    private var observations = [Any]()

    init(notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.notificationCenter = notificationCenter

        let notificationNames = [UIResponder.keyboardDidShowNotification, UIResponder.keyboardDidHideNotification]

        observations.append(contentsOf: notificationNames.map { notificationName in
            notificationCenter.addObserver(forName: notificationName, object: nil, queue: nil) { [weak self] notification in
                self?.updateState(from: notification)
            }
        })
    }

    private func updateState(from notification: Notification) {
        state = KeyboardState(
            isVisible: notification.name == UIResponder.keyboardDidShowNotification,
            frameEnd: notification.keyboardFrameEnd ?? .zero
        )
    }

    deinit {
        observations.forEach(notificationCenter.removeObserver)
    }
}

private extension Notification {
    /// The `CGRect` value of `UIResponder.keyboardFrameEndUserInfoKey` from self.
    ///
    var keyboardFrameEnd: CGRect? {
        guard let rectAsValue = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return nil
        }

        return rectAsValue.cgRectValue
    }
}
