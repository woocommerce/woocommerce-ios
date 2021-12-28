import SwiftUI
import Networking

/// Represents the Customer section
///
struct OrderCustomerSection: View {
    let geometry: GeometryProxy

    /// View model to drive the view content
    let viewModel: NewOrderViewModel.CustomerDataViewModel

    /// View model to access navigation flow
    @ObservedObject var orderViewModel: NewOrderViewModel

    @State private var showAddressForm: Bool = false

    var body: some View {
        Group {
            Divider()

            VStack(alignment: .leading) {
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

                if !viewModel.isDataAvailable {
                    createCustomerView
                } else {
                    customerDataView
                }
            }
            .padding(.horizontal, insets: geometry.safeAreaInsets)
            .padding()
            .background(Color(.listForeground))

            Divider()
        }
    }

    private var createCustomerView: some View {
        Button(Localization.addCustomer) {
            showAddressForm.toggle()
        }
        .buttonStyle(PlusButtonStyle())
        .sheet(isPresented: $showAddressForm) {
            NavigationView {
                EditOrderAddressForm(dismiss: {
                    showAddressForm.toggle()
                }, viewModel: CreateOrderAddressFormViewModel(siteID: orderViewModel.siteID,
                                                              address: orderViewModel.orderDetails.billingAddress,
                                                              onAddressUpdate: { updatedAddress in
                    orderViewModel.orderDetails.billingAddress = updatedAddress
                }))
            }
        }
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
            if let billingAddressFormatted = viewModel.billingAddressFormatted {
                addressDetails(title: Localization.billingTitle, formattedAddress: billingAddressFormatted)
            }
            if let shippingAddressFormatted = viewModel.shippingAddressFormatted {
                addressDetails(title: Localization.shippingTitle, formattedAddress: shippingAddressFormatted)
            }
        }
    }

    @ViewBuilder private func addressDetails(title: String, formattedAddress: String) -> some View {
        Divider()
        VStack(alignment: .leading, spacing: Layout.verticalAddressSpacing) {
            Text(title)
                .headlineStyle()
            Text(formattedAddress)
                .bodyStyle()
        }
    }
}

// MARK: Constants
private extension OrderCustomerSection {
    enum Layout {
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
    }
}

struct OrderCustomerSection_Previews: PreviewProvider {
    static var previews: some View {
        let orderViewModel = NewOrderViewModel(siteID: 123)
        let emptyViewModel = NewOrderViewModel.CustomerDataViewModel(billingAddress: nil, shippingAddress: nil)
        let addressViewModel = NewOrderViewModel.CustomerDataViewModel(fullName: "Johnny Appleseed",
                                                                       email: "scrambled@scrambled.com",
                                                                       billingAddressFormatted: """
                                                                            Johnny Appleseed
                                                                            234 70th Street
                                                                            Niagara Falls NY 14304
                                                                            US
                                                                            """,
                                                                       shippingAddressFormatted: nil)

        GeometryReader { geometry in
            ScrollView {
                OrderCustomerSection(geometry: geometry, viewModel: emptyViewModel, orderViewModel: orderViewModel)
                OrderCustomerSection(geometry: geometry, viewModel: addressViewModel, orderViewModel: orderViewModel)
            }
        }
    }
}
