import SwiftUI

/// Represents the Customer section
///
struct OrderCustomerSection: View {

    /// View model to drive the view content
    let viewModel: NewOrderViewModel.CustomerDataViewModel

    /// View model for Address Form
    let addressFormViewModel: CreateOrderAddressFormViewModel

    @State private var showAddressForm: Bool = false

    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    var body: some View {
        Group {
            Divider()

            VStack(alignment: .leading, spacing: .zero) {
                HStack(alignment: .top) {
                    Text(Localization.customer)
                        .headlineStyle()

                    Spacer()

                    if viewModel.isDataAvailable {
                        Button(Localization.editButton) {
                            showAddressForm.toggle()
                        }
                        .buttonStyle(LinkButtonStyle())
                        .fixedSize(horizontal: true, vertical: true)
                        .padding(.top, -Layout.linkButtonTopPadding) // remove padding to align button title to the top
                        .padding(.trailing, -Layout.linkButtonTrailingPadding) // remove padding to align button title to the side
                    }
                }
                .padding([.leading, .top, .trailing])

                Spacer(minLength: Layout.verticalHeadlineSpacing)

                if !viewModel.isDataAvailable {
                    createCustomerView
                } else {
                    customerDataView
                }
            }
            .padding(.horizontal, insets: safeAreaInsets)
            .background(Color(.listForeground))

            Divider()
        }
        .sheet(isPresented: $showAddressForm) {
            NavigationView {
                EditOrderAddressForm(dismiss: {
                    showAddressForm.toggle()
                }, viewModel: addressFormViewModel)
            }
        }
    }

    private var createCustomerView: some View {
        Button(Localization.addCustomer) {
            showAddressForm.toggle()
        }
        .buttonStyle(PlusButtonStyle())
        .padding([.leading, .bottom, .trailing])
    }

    private var customerDataView: some View {
        Group {
            VStack(alignment: .leading, spacing: Layout.verticalEmailSpacing) {
                if let fullName = viewModel.fullName {
                    Text(fullName)
                        .bodyStyle()
                }
                if let email = viewModel.email {
                    Text(email)
                        .footnoteStyle()
                }
            }
            .padding([.leading, .bottom, .trailing])
            .padding(.top, -Layout.linkButtonTopPadding)
            if let shippingAddressFormatted = viewModel.shippingAddressFormatted {
                addressDetails(title: Localization.shippingTitle, formattedAddress: shippingAddressFormatted)
            }
            Divider()
                .padding(.leading)
            NavigationRow(content: {
                Text(Localization.showBilling)
                    .bodyStyle()
            }, action: {
            })
        }
    }

    @ViewBuilder private func addressDetails(title: String, formattedAddress: String) -> some View {
        Divider()
            .padding(.leading)
        VStack(alignment: .leading, spacing: Layout.verticalAddressSpacing) {
            Text(title)
                .headlineStyle()
            Text(formattedAddress)
                .bodyStyle()
        }
        .padding()
    }
}

// MARK: Constants
private extension OrderCustomerSection {
    enum Layout {
        static let verticalHeadlineSpacing: CGFloat = 22.0
        static let verticalEmailSpacing: CGFloat = 4.0
        static let verticalAddressSpacing: CGFloat = 6.0
        static let linkButtonTopPadding: CGFloat = 12.0
        static let linkButtonTrailingPadding: CGFloat = 22.0
    }

    enum Localization {
        static let customer = NSLocalizedString("Customer", comment: "Title text of the section that shows Customer details when creating a new order")
        static let addCustomer = NSLocalizedString("Add customer", comment: "Title text of the button that adds a customer when creating a new order")
        static let editButton = NSLocalizedString("Edit", comment: "Button to edit a customer on the New Order screen")

        static let billingTitle = NSLocalizedString("Billing Address", comment: "Title for the Billing Address section in order customer data")
        static let shippingTitle = NSLocalizedString("Shipping Address", comment: "Title for the Edit Shipping Address section in order customer data")

        static let showBilling = NSLocalizedString("View Billing Information",
                                                   comment: "Button on bottom of customer section to show the summary view")
    }
}

@available(iOS 15.0, *)
struct OrderCustomerSection_Previews: PreviewProvider {
    static var previews: some View {
        let orderAdressFormViewModel = NewOrderViewModel(siteID: 123).createOrderAddressFormViewModel()
        let emptyViewModel = NewOrderViewModel.CustomerDataViewModel(billingAddress: nil, shippingAddress: nil)
        let addressViewModel = NewOrderViewModel.CustomerDataViewModel(fullName: "Johnny Appleseed",
                                                                       email: "scrambled@scrambled.com",
                                                                       billingAddressFormatted: nil,
                                                                       shippingAddressFormatted: """
                                                                            Johnny Appleseed
                                                                            234 70th Street
                                                                            Niagara Falls NY 14304
                                                                            US
                                                                            """)

        ScrollView {
            OrderCustomerSection(viewModel: emptyViewModel, addressFormViewModel: orderAdressFormViewModel)
            OrderCustomerSection(viewModel: addressViewModel, addressFormViewModel: orderAdressFormViewModel)
        }
    }
}
