import SwiftUI

/// Represents the Customer section
///
struct OrderCustomerSection: View {

    /// Parent view model to access all data
    @ObservedObject var viewModel: NewOrderViewModel

    /// View model to drive the view content
    private var customerDataViewModel: NewOrderViewModel.CustomerDataViewModel {
        viewModel.customerDataViewModel
    }

    @State private var showAddressForm: Bool = false

    var body: some View {
        OrderCustomerSectionContent(viewModel: viewModel.customerDataViewModel, showAddressForm: $showAddressForm)
        .sheet(isPresented: $showAddressForm) {
            NavigationView {
                EditOrderAddressForm(dismiss: {
                    showAddressForm.toggle()
                }, viewModel: viewModel.createOrderAddressFormViewModel())
            }
        }
    }
}

private struct OrderCustomerSectionContent: View {

    /// View model to drive the view content
    var viewModel: NewOrderViewModel.CustomerDataViewModel

    @Binding var showAddressForm: Bool

    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    var body: some View {
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

            if !viewModel.isDataAvailable {
                Spacer(minLength: Layout.verticalHeadlineSpacing)
                createCustomerView
            } else {
                customerDataView
            }
        }
        .padding(.horizontal, insets: safeAreaInsets)
        .background(Color(.listForeground))

        Divider()
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
            addressDetails(title: Localization.shippingTitle, formattedAddress: viewModel.shippingAddressFormatted)
            Divider()
                .padding(.leading)
            addressDetails(title: Localization.billingTitle, formattedAddress: viewModel.billingAddressFormatted)
        }
    }

    @ViewBuilder private func addressDetails(title: String, formattedAddress: String?) -> some View {
        VStack(alignment: .leading, spacing: Layout.verticalAddressSpacing) {
            Text(title)
                .headlineStyle()
            if let formattedAddress = formattedAddress, formattedAddress.isNotEmpty {
                Text(formattedAddress)
                    .bodyStyle()
            } else {
                Text(Localization.noAddress)
                    .bodyStyle()
            }
        }
        .padding()
    }
}

// MARK: Constants
private extension OrderCustomerSectionContent {
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

        static let noAddress = NSLocalizedString("No address specified.", comment: "Placeholder for empty address in order customer data")
    }
}

@available(iOS 15.0, *)
struct OrderCustomerSection_Previews: PreviewProvider {
    static var previews: some View {
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
            OrderCustomerSectionContent(viewModel: emptyViewModel, showAddressForm: .constant(false))
            OrderCustomerSectionContent(viewModel: addressViewModel, showAddressForm: .constant(false))
        }
    }
}
