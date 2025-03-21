import SwiftUI

struct SiteNotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var orderNotificationsEnabled: Bool
    @State private var productReviewsNotificationsEnabled: Bool

    typealias CompletionCallback = (_ orderNotificationsEnabled: Bool, _ productReviewsNotificationsEnabled: Bool) -> Void

    private let siteTitle: String
    private let completionHandler: CompletionCallback
    private let initialValues: (newOrders: Bool, productReviews: Bool)

    var hasChanges: Bool {
        initialValues.newOrders != orderNotificationsEnabled ||
        initialValues.productReviews != productReviewsNotificationsEnabled
    }

    init(siteTitle: String,
         ordersNotificationsEnabled: Bool,
         productReviewsNotificationsEnabled: Bool,
         completionHandler: @escaping CompletionCallback) {
        self.siteTitle = siteTitle
        self.orderNotificationsEnabled = ordersNotificationsEnabled
        self.productReviewsNotificationsEnabled = productReviewsNotificationsEnabled
        self.completionHandler = completionHandler
        self.initialValues = (ordersNotificationsEnabled, productReviewsNotificationsEnabled)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $orderNotificationsEnabled) {
                        Text(Localization.newOrders)
                    }
                    Toggle(isOn: $productReviewsNotificationsEnabled) {
                        Text(Localization.productReviews)
                    }
                } header: {
                    Text(siteTitle)
                } footer: {
                    Text(Localization.notificationTypesFooter)
                }
            }
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.update) {
                        completionHandler(orderNotificationsEnabled, productReviewsNotificationsEnabled)
                        dismiss()
                    }
                    .disabled(hasChanges == false)
                }
            }
        }
    }
}

private extension SiteNotificationSettingsView {
    enum Localization {
        static let cancel = NSLocalizedString(
            "siteNotificationSettingsView.cancel",
            value: "Cancel",
            comment: "Button to dismiss the site notification settings view"
        )
        static let update = NSLocalizedString(
            "siteNotificationSettingsView.update",
            value: "Update",
            comment: "Button to confirm the settings on the site notification settings view"
        )
        static let title = NSLocalizedString(
            "siteNotificationSettingsView.title",
            value: "Notification types",
            comment: "Header of the notification types section on the site notification settings view"
        )
        static let notificationTypesFooter = NSLocalizedString(
            "siteNotificationSettingsView.notificationTypesFooter",
            value: "Settings for push notifications that appear on your mobile device.",
            comment: "Footer of the notification types section on the site notification settings view"
        )
        static let newOrders = NSLocalizedString(
            "siteNotificationSettingsView.newOrders",
            value: "New orders",
            comment: "Label of the toggle to enable/disable new order notifications on the site notification settings view"
        )
        static let productReviews = NSLocalizedString(
            "siteNotificationSettingsView.productReviews",
            value: "Product reviews",
            comment: "Label of the toggle to enable/disable product reviews notifications on the site notification settings view"
        )
    }
}
