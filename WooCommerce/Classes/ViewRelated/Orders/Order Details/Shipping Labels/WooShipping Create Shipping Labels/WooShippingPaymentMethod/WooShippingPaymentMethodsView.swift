import SwiftUI

struct WooShippingPaymentMethodsView: View {

    @ObservedObject var viewModel: ShippingLabelPaymentMethodsViewModel

    var body: some View {
        ScrollableVStack(alignment: .leading, padding: Layout.contentPadding, spacing: Layout.contentSpacing) {
            Text(Localization.title)
                .font(.title3)
                .bold()

            Text(Localization.subtitle)

            if viewModel.paymentMethods.isEmpty {
                emptyView
            } else {
                paymentMethodList
            }

            Spacer()

            Text(String(format: Localization.note, viewModel.storeOwnerUsername))
                .frame(maxWidth: .infinity, alignment: .leading)
                .footnoteStyle()
        }
        .padding(.top, Layout.contentPadding)
    }
}

private extension WooShippingPaymentMethodsView {
    var emptyView: some View {
        VStack(spacing: Layout.EmptyView.contentSpacing) {
            Image(uiImage: .creditCardIllustration)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Layout.EmptyView.imageSize, height: Layout.EmptyView.imageSize)

            VStack(spacing: Layout.EmptyView.textSpacing) {
                Text(Localization.EmptyView.title)
                    .font(.subheadline)
                    .bold()
                Text(Localization.EmptyView.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            Button {
                // TODO
            } label: {
                Label {
                    Text(Localization.EmptyView.actionButton)
                } icon: {
                    Image(uiImage: .externalImage)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(Layout.EmptyView.contentInsets)
        .background(
            RoundedRectangle(cornerRadius: Layout.EmptyView.corderRadius)
                .stroke(Color(.border), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        )
        .padding(.top, Layout.contentSpacing)
    }

    var paymentMethodList: some View {
        EmptyView() // TODO
    }
}

private extension WooShippingPaymentMethodsView {
    enum Layout {
        static let contentPadding: CGFloat = 16
        static let contentSpacing: CGFloat = 8
        enum EmptyView {
            static let corderRadius: CGFloat = 8
            static let contentInsets = EdgeInsets(top: 54, leading: 32, bottom: 54, trailing: 32)
            static let contentSpacing: CGFloat = 16
            static let textSpacing: CGFloat = 8
            static let imageSize: CGFloat = 88
        }
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
            value: "Credit cards are retrieved from the following WordPress.com account: @%1$@.",
            comment: "Note of the payment method sheet in the Shipping Label purchase flow. " +
            "Placeholder is the username of an associated WordPress account. Please keep the `@` in front of the placeholder."
        )
    }
}

#Preview {
    WooShippingPaymentMethodsView(viewModel: .init(accountSettings: ShippingLabelPaymentMethodsViewModel.sampleAccountSettings()))
}
