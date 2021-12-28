import SwiftUI
import Networking

/// Represents the Customer section
///
struct OrderCustomerSection: View {
    let geometry: GeometryProxy

    /// View model to drive the view content
    @ObservedObject var viewModel: NewOrderViewModel

    @State private var showAddressForm: Bool = false

    var body: some View {
        Group {
            Divider()

            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Text(Localization.customer)
                        .headlineStyle()

                    Spacer()

                    if viewModel.customerDataViewModel.isDataAvailable {
                        Button(Localization.editButton) {
                            showAddressForm.toggle()
                        }
                        .buttonStyle(LinkButtonStyle())
                        .fixedSize(horizontal: true, vertical: true)
                        .padding(.top, -Layout.linkButtonTopPadding) // remove padding to align button title to the top
                        .padding(.trailing, -Layout.linkButtonTrailingPadding) // remove padding to align button title to the side
                    }
                }

                if !viewModel.customerDataViewModel.isDataAvailable {
                    createCustomerView
                } else {
                    VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
                        if let fullName = viewModel.customerDataViewModel.fullName {
                            Text(fullName)
                                .bodyStyle()
                        }
                        if let email = viewModel.customerDataViewModel.email {
                            Text(email)
                                .footnoteStyle()
                        }
                    }
                    if let billingAddressFormatted = viewModel.customerDataViewModel.billingAddressFormatted {
                        Divider()
                        Text(Localization.billingTitle)
                            .headlineStyle()
                        Spacer()
                        Text(billingAddressFormatted)
                            .bodyStyle()
                    }
                    if let shippingAddressFormatted = viewModel.customerDataViewModel.shippingAddressFormatted {
                        Divider()
                        Text(Localization.shippingTitle)
                            .headlineStyle()
                        Spacer()
                        Text(shippingAddressFormatted)
                            .bodyStyle()
                    }
                }
            }
            .padding(.horizontal, insets: geometry.safeAreaInsets)
            .padding()
            .background(Color(.listForeground))

            Divider()
        }
    }

    var createCustomerView: some View {
        Button(Localization.addCustomer) {
            showAddressForm.toggle()
        }
        .buttonStyle(PlusButtonStyle())
        .sheet(isPresented: $showAddressForm) {
            NavigationView {
                EditOrderAddressForm(dismiss: {
                    showAddressForm.toggle()
                }, viewModel: CreateOrderAddressFormViewModel(siteID: viewModel.siteID,
                                                              address: viewModel.orderDetails.billingAddress,
                                                              onAddressUpdate: { updatedAddress in
                    viewModel.orderDetails.billingAddress = updatedAddress
                }))
            }
        }
    }
}

// MARK: Constants
private extension OrderCustomerSection {
    enum Layout {
        static let verticalSpacing: CGFloat = 4.0
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
        let emptyViewModel = NewOrderViewModel(siteID: 123)
        let viewModel: NewOrderViewModel = {
            let vm = NewOrderViewModel(siteID: 123)
            let sampleAddress = Address(firstName: "Johnny",
                                        lastName: "Appleseed",
                                        company: nil,
                                        address1: "234 70th Street",
                                        address2: nil,
                                        city: "Niagara Falls",
                                        state: "NY",
                                        postcode: "14304",
                                        country: "US",
                                        phone: "333-333-3333",
                                        email: "scrambled@scrambled.com")

            vm.orderDetails.billingAddress = sampleAddress
            vm.orderDetails.shippingAddress = sampleAddress
            return vm
        }()

        GeometryReader { geometry in
            ScrollView {
                OrderCustomerSection(geometry: geometry, viewModel: emptyViewModel)
                OrderCustomerSection(geometry: geometry, viewModel: viewModel)
            }
        }
    }
}
