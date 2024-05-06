import SwiftUI

struct OrderCustomerSection: View {
    @ObservedObject var viewModel: OrderCustomerSectionViewModel

    var body: some View {
        Group {
            if let cardViewModel = viewModel.cardViewModel {
                CollapsibleCustomerCard(viewModel: cardViewModel)
                    .padding()
            } else {
                createCustomerView
                    .frame(minHeight: Layout.buttonHeight)
            }
        }
        .background(Color(.listForeground(modal: true)))
    }

    private var createCustomerView: some View {
        Button(Localization.addCustomerDetails) {
            viewModel.addCustomerDetails()
        }
        .buttonStyle(PlusButtonStyle())
        .padding([.leading, .trailing])
    }
}

// MARK: Constants
private extension OrderCustomerSection {
    enum Layout {
        static let buttonHeight: CGFloat = 56.0
    }

    enum Localization {
        static let addCustomerDetails = NSLocalizedString("orderForm.customerSection.addCustomer",
                                                          value: "Add Customer",
                                                          comment: "Title text of the button that adds customer data when creating a new order")
    }
}

struct OrderCustomerSection_Previews: PreviewProvider {
    static let customer: CollapsibleCustomerCardViewModel.CustomerData = .init(
        email: "customer@woo.com",
        fullName: "T Woo",
        billingAddressFormatted: "123 60th St\nUSA",
        shippingAddressFormatted: nil
    )
    static var previews: some View {
        Group {
            OrderCustomerSection(viewModel: .init(customerData: customer, isCustomerAccountRequired: true, isEditable: true))
            OrderCustomerSection(viewModel: .init(customerData: customer, isCustomerAccountRequired: false, isEditable: true))
        }
    }
}
