import UIKit
import UserNotifications
import UserNotificationsUI
import SwiftUI

class OrderNotificationViewController: UIViewController, UNNotificationContentExtension {

    @MainActor @IBOutlet var label: UILabel?
    @MainActor @IBOutlet var loadingIndicator: UIActivityIndicatorView?

    let viewModel = OrderNotificationViewModel()
    var hostingView: UIHostingController<OrderNotificationView>!

    func didReceive(_ notification: UNNotification) {

        // Show loading Indicator
        self.loadingIndicator?.isHidden = false

        Task {
            do {
                // Hide loading indicator after do block is finished.
                defer {
                    self.loadingIndicator?.isHidden = true
                }

                // Load notification, order and render order view.
                let note = try await viewModel.loadNotification(notification)
                let order = try await viewModel.loadOrder(for: note)
                let content = viewModel.formatContent(note: note, order: order)
                addOrderNotificationView(with: content)

            } catch {
                self.label?.text = AppLocalizedString("Unable to load notification",
                                                      comment: "Text when failing to load a notification after long pressing on it.")
            }
        }
    }

    @MainActor
    private func addOrderNotificationView(with content: OrderNotificationView.Content) {
        let orderView = OrderNotificationView(content: content)
        hostingView = UIHostingController(rootView: orderView)

        self.view.addSubview(hostingView.view)
        hostingView.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingView.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}
