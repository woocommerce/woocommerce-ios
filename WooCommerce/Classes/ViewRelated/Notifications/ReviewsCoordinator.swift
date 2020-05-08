
import Foundation
import UIKit

/// Coordinator for the Reviews tab.
///
final class ReviewsCoordinator: Coordinator {
    var navigationController: UINavigationController

    private let pushNotificationsManager: PushNotesManager

    private var observationToken: ObservationToken?

    init(pushNotificationsManager: PushNotesManager = ServiceLocator.pushNotesManager) {
        self.pushNotificationsManager = pushNotificationsManager

        self.navigationController = WooNavigationController(rootViewController: ReviewsViewController())
    }

    deinit {
        observationToken?.cancel()
    }

    func start() {
        observationToken = pushNotificationsManager.inactiveNotifications.subscribe { [weak self] in
            self?.handleInactiveNotification($0)
        }
    }

    private func handleInactiveNotification(_ notification: ForegroundNotification) {
        guard notification.kind == .comment else {
            return
        }


    }
}
