import SwiftUI

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
    }
}

#Preview {
    NotificationSettingsView()
}
