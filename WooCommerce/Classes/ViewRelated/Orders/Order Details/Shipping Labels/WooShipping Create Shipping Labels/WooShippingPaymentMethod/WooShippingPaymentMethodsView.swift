import SwiftUI
import struct Yosemite.ShippingLabelPaymentMethod

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

            HStack(alignment: .top) {
                Image(systemName: "info.circle")
                Text(String(format: Localization.note, viewModel.storeOwnerUsername))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.footnote)
            .foregroundStyle(Color.primary)

            Spacer()

            if viewModel.paymentMethods.isNotEmpty {
                VStack(spacing: Layout.contentPadding) {
                    Divider()
                        .padding(.horizontal, -Layout.contentPadding) // hack to cancel the padding set by parent

                    Toggle(isOn: $viewModel.isEmailReceiptsEnabled) {
                        Text(Localization.emailReceipt)
                    }
                    .toggleStyle(.switch)

                    Button(Localization.confirmButton) {
                        // TODO
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isDoneButtonEnabled() == false)
                }
            }
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
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(.border), style: StrokeStyle(dash: [4, 4]))
        )
        .padding(.top, Layout.contentSpacing)
    }

    var paymentMethodList: some View {
        VStack {
            ForEach(viewModel.paymentMethods, id: \.paymentMethodID) { method in
                Button {
                    viewModel.didSelectPaymentMethod(withID: method.paymentMethodID)
                } label: {
                    VStack(alignment: .leading) {
                        Text(method.cardLineTitle)
                            .bold()
                        Text(method.name)
                        Text(method.expiryString)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Layout.contentPadding)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: Layout.cornerRadius)
                            .fill(isSelectedMethod(method) ? Layout.selectedBackgroundColor : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                                    .stroke(
                                        isSelectedMethod(method) ? Color.accentColor : Color(.border),
                                        lineWidth: isSelectedMethod(method) ? Layout.selectedBorderWidth : Layout.borderWidth
                                    )
                            )
                    )
                }
            }
            .buttonStyle(.plain)

            Button {
                // TODO
            } label: {
                HStack(spacing: Layout.contentPadding) {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.accentColor)
                    Text(Localization.EmptyView.actionButton)
                }
                .font(.subheadline)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Layout.contentPadding)
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: Layout.cornerRadius)
                        .stroke(Color(.border))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Layout.contentPadding)
    }

    func isSelectedMethod(_ method: ShippingLabelPaymentMethod) -> Bool {
        method.paymentMethodID == viewModel.selectedPaymentMethodID
    }
}

private extension WooShippingPaymentMethodsView {
    enum Layout {
        static let contentPadding: CGFloat = 16
        static let contentSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 8
        static let borderWidth: CGFloat = 0.5
        static let selectedBorderWidth: CGFloat = 2
        enum EmptyView {
            static let contentInsets = EdgeInsets(top: 54, leading: 32, bottom: 54, trailing: 32)
            static let contentSpacing: CGFloat = 16
            static let textSpacing: CGFloat = 8
            static let imageSize: CGFloat = 88
        }
        static let selectedBackgroundColor = Color(
            light: .withColorStudio(name: .wooCommercePurple, shade: .shade0),
            dark: .withColorStudio(name: .wooCommercePurple, shade: .shade80)
        )
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
        static let emailReceipt = NSLocalizedString(
            "wooShippingPaymentMethodsView.emailReceipt",
            value: "Email the receipt",
            comment: "Label of the toggle to enable emailing receipt upon purchasing a shipping label"
        )
        static let confirmButton = NSLocalizedString(
            "wooShippingPaymentMethodsView.confirmButton",
            value: "Use this card",
            comment: "Button to confirm a credit/debit for purchasing a shipping label"
        )
    }
}

#Preview {
    WooShippingPaymentMethodsView(viewModel: .init(accountSettings: ShippingLabelPaymentMethodsViewModel.sampleAccountSettings()))
}
