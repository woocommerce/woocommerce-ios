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
    @StateObject private var viewModel: NotificationSettingsViewModel

    init() {
        self._viewModel = StateObject(wrappedValue: NotificationSettingsViewModel())
    }

    var body: some View {
        Group {
            if viewModel.notificationsEnabled {
                notificationTypesForm
            } else {
                notificationsDisabledView
            }
        }
        .navigationTitle(Localization.title)
    }
}

private extension NotificationSettingsView {
    var notificationsDisabledView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "app.badge.fill")
                .font(.largeTitle)

            Text(Localization.notificationsDisabled)

            Button(Localization.enableNotificationsCTA) {
                Task {
                    await openSettingsApp()
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            Spacer()
        }
        .scrollVerticallyIfNeeded()
        .padding(.horizontal)
    }

    var notificationTypesForm: some View {
        Form {
            Section {
                HStack {
                    Text(Localization.notificationsEnabled)
                    Spacer()
                    Button(Localization.settingsAppCTA) {
                        Task {
                            await openSettingsApp()
                        }
                    }
                }
            } footer: {
                Text(Localization.notificationsFooter)
            }
            Section {
                Toggle(isOn: $viewModel.orderNotificationsEnabled) {
                    Text(Localization.newOrders)
                }
                Toggle(isOn: $viewModel.productReviewNotificationsEnabled) {
                    Text(Localization.productReviews)
                }
            } header: {
                Text(Localization.notificationTypesHeader)
            } footer: {
                Text(Localization.notificationTypesFooter)
            }
        }
    }

    func openSettingsApp() async {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else {
            return
        }
        // Ask the system to open that URL.
        await UIApplication.shared.open(url)
    }
}

extension NotificationSettingsView {
    enum Localization {
        static let title = NSLocalizedString(
            "notificationSettingsView.title",
            value: "Notification Settings",
            comment: "Title of the notification settings view"
        )
        static let notificationsDisabled = NSLocalizedString(
            "notificationSettingsView.notificationsDisabled",
            value: "Notifications are disabled for Woo",
            comment: "Label indicating notifications are disabled on the notification settings view"
        )
        static let enableNotificationsCTA = NSLocalizedString(
            "notificationSettingsView.enableNotificationsCTA",
            value: "Enable notifications",
            comment: "Button to enable notifications on the notification settings view"
        )
        static let notificationsEnabled = NSLocalizedString(
            "notificationSettingsView.notificationsEnabled",
            value: "Notifications enabled",
            comment: "Label indicating notifications are enabled on the notification settings view"
        )
        static let settingsAppCTA = NSLocalizedString(
            "notificationSettingsView.settingsAppCTA",
            value: "Change",
            comment: "Button to open the app's notification settings in the Settings app"
        )
        static let notificationsFooter = NSLocalizedString(
            "notificationSettingsView.notificationsFooter",
            value: "Including in-app reminders and remote push notifications.",
            comment: "Footer of the notifications section on the notification settings view"
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
