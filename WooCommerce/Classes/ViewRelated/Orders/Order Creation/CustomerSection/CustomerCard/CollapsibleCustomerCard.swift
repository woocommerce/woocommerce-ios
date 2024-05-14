import SwiftUI

/// Displays a collapsible customer card that shows customer details in the collapsed and expanded states.
struct CollapsibleCustomerCard: View {
    @ObservedObject private var viewModel: CollapsibleCustomerCardViewModel

    init(viewModel: CollapsibleCustomerCardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        CollapsibleOrderFormCard(hasSubtleChevron: true,
                                 isCollapsed: $viewModel.isCollapsed,
                                 showsBorder: true,
                                 padding: Layout.headerAdditionalPadding,
                                 label: {
            CollapsibleCustomerCardHeaderView(isCollapsed: viewModel.isCollapsed,
                                              email: viewModel.email,
                                              emailPlaceholder: viewModel.emailPlaceholder,
                                              shippingAddress: viewModel.shippingAddress)
        }, content: {
            VStack(alignment: .leading, spacing: Layout.expandedContentVerticalSpacing) {
                Divider()

                VStack(alignment: .leading) {
                    Text(Localization.emailAddressTitle)
                    TextField(Localization.emailAddressPlaceholder, text: $viewModel.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle(focused: true))
                }

                Text("Create new customer toggle")

                Divider()

                CollapsibleCustomerCardAddressView(viewModel: viewModel.addressViewModel)

                removeCustomerView()
                    .renderedIf(viewModel.canRemoveCustomer)
            }
            .padding(Layout.expandedContentPadding)
        })
    }
}

private extension CollapsibleCustomerCard {
    @ViewBuilder private func removeCustomerView() -> some View {
        Button {
            viewModel.removeCustomer()
        } label: {
            HStack(alignment: .center) {
                Label {
                    Text(Localization.removeCustomer)
                } icon: {
                    Image(systemName: "multiply.circle")
                }
            }
        }
        .foregroundColor(Color(uiColor: .withColorStudio(.red, shade: .shade60)))
    }
}

private extension CollapsibleCustomerCard {
    enum Layout {
        static let headerAdditionalPadding: EdgeInsets = .init(top: 8, leading: 0, bottom: 8, trailing: 0)
        static let expandedContentPadding: EdgeInsets = .init(top: 0, leading: 16, bottom: 16, trailing: 16)
        static let expandedContentVerticalSpacing: CGFloat = 16
    }

    enum Localization {
        static let emailAddressTitle = NSLocalizedString(
            "collapsibleCustomerCard.emailTextField.title",
            value: "Email address",
            comment: "Title of the email text field in the order form customer card."
        )
        static let emailAddressPlaceholder = NSLocalizedString(
            "collapsibleCustomerCard.emailTextField.placeholder",
            value: "Enter email address",
            comment: "Title of the email text field in the order form customer card."
        )
        static let removeCustomer = NSLocalizedString(
            "collapsibleCustomerCard.removeCustomerButton.title",
            value: "Remove customer from order",
            comment: "Title of the button to remove customer from an order in the order form customer card."
        )
    }
}

struct CollapsibleCustomerCard_Previews: PreviewProvider {
    static var previews: some View {
        CollapsibleCustomerCard(viewModel: .init(customerData: .init(customerID: nil,
                                                                     email: nil,
                                                                     fullName: nil,
                                                                     billingAddressFormatted: nil,
                                                                     shippingAddressFormatted: nil),
                                                 isCustomerAccountRequired: true,
                                                 isEditable: true,
                                                 isCollapsed: false,
                                                 removeCustomer: {},
                                                 editAddress: {}))
    }
}
