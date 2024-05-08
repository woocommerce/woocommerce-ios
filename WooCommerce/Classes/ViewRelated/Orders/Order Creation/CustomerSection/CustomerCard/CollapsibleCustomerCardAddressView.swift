import SwiftUI

/// Shows a customer's address if available, with a CTA to add/edit the address.
struct CollapsibleCustomerCardAddressView: View {
    let viewModel: CollapsibleCustomerCardAddressViewModel

    enum State {
        case addAddress
        case sameBillingAndShippingAddress(address: String)
        case billingOnly(address: String)
        case shippingOnly(address: String)
        case differentBillingAndShippingAddresses(billing: String, shipping: String)
    }

    var body: some View {
        switch viewModel.state {
            case .addAddress:
                addAddressView()
            case let .sameBillingAndShippingAddress(address), let .billingOnly(address), let .shippingOnly(address):
                VStack(alignment: .leading, spacing: Layout.addressVerticalSpacing) {
                    editableAddressHeaderView(title: Localization.addressHeader)
                    Text(address)
                }
            case let .differentBillingAndShippingAddresses(billing, shipping):
                VStack(alignment: .leading, spacing: Layout.addressVerticalSpacing) {
                    editableAddressHeaderView(title: Localization.billingAddressHeader)
                    Text(billing)

                    Text(Localization.shippingAddressHeader)
                        .headlineStyle()
                    Text(shipping)
                }
        }
    }
}

private extension CollapsibleCustomerCardAddressView {
    @ViewBuilder private func addAddressView() -> some View {
        Button(Localization.addAddress, action: {
            viewModel.editAddress()
        })
        .buttonStyle(PlusButtonStyle())
    }

    @ViewBuilder private func editableAddressHeaderView(title: String) -> some View {
        HStack {
            Text(title)
                .headlineStyle()
            Spacer()
            Button(action: {
                viewModel.editAddress()
            }, label: {
                Image(systemName: "pencil")
            })
            .buttonStyle(TextButtonStyle())
        }
    }
}

private extension CollapsibleCustomerCardAddressView {
    enum Layout {
        static let addressVerticalSpacing: CGFloat = 8
    }

    enum Localization {
        static let addAddress = NSLocalizedString(
            "collapsibleCustomerCard.addAddress.title",
            value: "Add customer address",
            comment: "Title of the button to add address in the order form customer card."
        )
        static let addressHeader = NSLocalizedString(
            "collapsibleCustomerCard.editAddress.address.header",
            value: "Address",
            comment: "Address header text in the order form customer card when the billing and shipping addresses are the same."
        )
        static let billingAddressHeader = NSLocalizedString(
            "collapsibleCustomerCard.editAddress.billing.header",
            value: "Billing address",
            comment: "Billing address header text in the order form customer card."
        )
        static let shippingAddressHeader = NSLocalizedString(
            "collapsibleCustomerCard.editAddress.shipping.header",
            value: "Shipping address",
            comment: "Shipping address header text in the order form customer card."
        )
    }
}

struct CollapsibleCustomerCardAddressView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CollapsibleCustomerCardAddressView(viewModel: .init(billingAddressFormatted: nil,
                                                                shippingAddressFormatted: nil,
                                                                editAddress: {}))
            CollapsibleCustomerCardAddressView(viewModel: .init(billingAddressFormatted: "311 16th St\nSan Francisco",
                                                                shippingAddressFormatted: nil,
                                                                editAddress: {}))
            CollapsibleCustomerCardAddressView(viewModel: .init(billingAddressFormatted: "311 16th St\nSan Francisco",
                                                                shippingAddressFormatted: "508 19th St",
                                                                editAddress: {}))
        }
    }
}
