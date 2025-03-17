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
        title = "Notification Settings"
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
                    Text("All notifications")
                }
            } footer: {
                Text("Including in-app reminders and remote push notifications.")
            }

            Section {
                Toggle(isOn: $orderNotificationsEnabled) {
                    Text("New orders")
                }
                .disabled(!notificationsEnabled)

                Toggle(isOn: $productReviewNotificationsEnabled) {
                    Text("Product reviews")
                }
                .disabled(!notificationsEnabled)
            } header: {
                Text("Notification types")
            } footer: {
                Text("Settings applied to all selected sites.")
            }
        }
        .navigationTitle("Notification Settings")
    }
}

#Preview {
    NotificationSettingsView()
}
