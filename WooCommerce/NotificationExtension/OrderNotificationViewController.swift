import UIKit
import UserNotifications
import UserNotificationsUI
import SwiftUI

final class OrderNotificationViewController: UIViewController, UNNotificationContentExtension {

    @MainActor @IBOutlet private var label: UILabel?
    @MainActor @IBOutlet private var loadingIndicator: UIActivityIndicatorView?

    let viewModel = OrderNotificationViewModel()
    var hostingView: UIHostingController<OrderNotificationView>!

    func didReceive(_ notification: UNNotification) {

        // Show loading Indicator
        loadingIndicator?.isHidden = false

        Task {
            do {

                // Load notification, order and render order view.
                let (note, order) = try await viewModel.loadOrder(from: notification)
                let content = viewModel.formatContent(note: note, order: order)
                addOrderNotificationView(with: content)
                loadingIndicator?.isHidden = true

            } catch {

                loadingIndicator?.isHidden = true
                label?.text = AppLocalizedString("Unable to load notification",
                                                 comment: "Text when failing to load a notification after long pressing on it.")
            }
        }
    }

    @MainActor
    private func addOrderNotificationView(with content: OrderNotificationView.Content) {
        let orderView = OrderNotificationView(content: content)
        hostingView = UIHostingController(rootView: orderView)

        view.addSubview(hostingView.view)
        hostingView.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingView.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}
