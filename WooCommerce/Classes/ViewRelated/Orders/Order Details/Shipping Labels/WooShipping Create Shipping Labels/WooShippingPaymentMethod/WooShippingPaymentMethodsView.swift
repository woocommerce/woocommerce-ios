import SwiftUI

struct WooShippingPaymentMethodsView: View {

    @ObservedObject var viewModel: WooShippingPaymentMethodsViewModel

    var body: some View {
        Text("Hello, World!")
    }
}

private extension WooShippingPaymentMethodsView {
    enum Localization {
        static let title = NSLocalizedString(
            "wooShippingPaymentMethodsView.title",
            value: "Payment method",
            comment: "Title of the payment method sheet in the Shipping Label purchase flow"
        )
        static let subtitle = NSLocalizedString(
            "wooShippingPaymentMethodsView.subtitle",
            value: "Choose a payment method.",
            comment: "Subtitle of the payment method sheet in the Shipping Label purchase flow"
        )
        enum EmptyView {
            static let title = NSLocalizedString(
                "wooShippingPaymentMethodsView.emptyView.title",
                value: "Add a payment method",
                comment: "Title of the payment method empty sheet in the Shipping Label purchase flow"
            )
            static let subtitle = NSLocalizedString(
                "wooShippingPaymentMethodsView.emptyView.subtitle",
                value: "Add a payment method to purchase a shipping label",
                comment: "Subtitle of the payment method empty sheet in the Shipping Label purchase flow"
            )
            static let actionButton = NSLocalizedString(
                "wooShippingPaymentMethodsView.emptyView.actionButton",
                value: "New credit or debit card",
                comment: "Action button on the payment method empty sheet in the Shipping Label purchase flow"
            )
        }
        static let note = NSLocalizedString(
            "wooShippingPaymentMethodsView.note",
            value: "Credit cards are retrieved from the following WordPress.com account: %1$@",
            comment: "Note of the payment method sheet in the Shipping Label purchase flow. " +
            "Placeholder is the username of an associated WordPress account."
        )
    }
}

#Preview {
    WooShippingPaymentMethodsView(viewModel: .init())
}
