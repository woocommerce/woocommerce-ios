import SwiftUI

final class NotificationSettingsHostingController: UIHostingController<NotificationSettingsView> {
    init() {
        super.init(rootView: NotificationSettingsView())
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NotificationSettingsView.Localization.title
    }
}

struct NotificationSettingsView: View {
    @State private var notificationsEnabled = false
    @State private var orderNotificationsEnabled = false
    @State private var productReviewNotificationsEnabled = false

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $notificationsEnabled) {
                    Text(Localization.allNotifications)
                }
            } footer: {
                Text(Localization.allNotificationsFooter)
            }

            Section {
                Toggle(isOn: $orderNotificationsEnabled) {
                    Text(Localization.newOrders)
                }
                .disabled(!notificationsEnabled)

                Toggle(isOn: $productReviewNotificationsEnabled) {
                    Text(Localization.productReviews)
                }
                .disabled(!notificationsEnabled)
            } header: {
                Text(Localization.notificationTypesHeader)
            } footer: {
                Text(Localization.notificationTypesFooter)
            }
        }
        .navigationTitle(Localization.title)
    }
}

extension NotificationSettingsView {
    enum Localization {
        static let title = NSLocalizedString(
            "notificationSettingsView.title",
            value: "Notification Settings",
            comment: "Title of the notification settings view"
        )
        static let allNotifications = NSLocalizedString(
            "notificationSettingsView.allNotifications",
            value: "All notifications",
            comment: "Label of the toggle to enable/disable all notifications on the notification settings view"
        )
        static let allNotificationsFooter = NSLocalizedString(
            "notificationSettingsView.allNotificationsFooter",
            value: "Including in-app reminders and remote push notifications.",
            comment: "Footer of the toggle to enable/disable all notifications on the notification settings view"
        )
        static let newOrders = NSLocalizedString(
            "notificationSettingsView.newOrders",
            value: "New orders",
            comment: "Label of the toggle to enable/disable new order notifications on the notification settings view"
        )
        static let productReviews = NSLocalizedString(
            "notificationSettingsView.productReviews",
            value: "Product reviews",
            comment: "Label of the toggle to enable/disable product reviews notifications on the notification settings view"
        )
        static let notificationTypesHeader = NSLocalizedString(
            "notificationSettingsView.notificationTypesHeader",
            value: "Notification types",
            comment: "Header of the notification types section on the notification settings view"
        )
        static let notificationTypesFooter = NSLocalizedString(
            "notificationSettingsView.notificationTypesFooter",
            value: "Settings applied to all selected sites.",
            comment: "Footer of the notification types section on the notification settings view"
        )
    }
}

#Preview {
    NotificationSettingsView()
}
