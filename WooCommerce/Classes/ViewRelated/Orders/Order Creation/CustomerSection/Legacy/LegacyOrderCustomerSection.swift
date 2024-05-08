import SwiftUI

/// Represents the Customer section
///
struct LegacyOrderCustomerSection: View {

    /// Parent view model to access all data
    @ObservedObject var viewModel: EditableOrderViewModel

    /// View model for the address form.
    ///
    @ObservedObject var addressFormViewModel: CreateOrderAddressFormViewModel

    @State private var showAddressForm: Bool = false

    var body: some View {
        OrderCustomerSectionContent(viewModel: viewModel.customerDataViewModel, showAddressForm: $showAddressForm)
            .sheet(isPresented: $showAddressForm) {
                NavigationView {
                    switch viewModel.customerNavigationScreen {
                    case .form:
                        EditOrderAddressForm(dismiss: { _ in
                                                showAddressForm.toggle()
                                             },
                                             viewModel: addressFormViewModel)
                    case .selector:
                        CustomerSelectorView(
                            siteID: viewModel.siteID,
                            configuration: .configurationForOrderCustomerSection,
                            addressFormViewModel: addressFormViewModel) { customer in
                            viewModel.addCustomerAddressToOrder(customer: customer)
                        }
                    }
                }
                .discardChangesPrompt(canDismiss: !addressFormViewModel.hasPendingChanges,
                                      didDismiss: addressFormViewModel.userDidCancelFlow)
                .onDisappear {
                    viewModel.resetAddressForm()
                }
            }
    }
}

private extension CustomerSelectorViewController.Configuration {
    static let configurationForOrderCustomerSection = CustomerSelectorViewController.Configuration(
        title: OrderCustomerLocalization.customerSelectorTitle,
        disallowSelectingGuest: false,
        disallowCreatingCustomer: false,
        showGuestLabel: false,
        shouldTrackCustomerAdded: true
    )

    enum OrderCustomerLocalization {
        static let customerSelectorTitle = NSLocalizedString(
            "configurationForOrderCustomerSection.customerSelectorTitle",
            value: "Add customer details",
            comment: "Title of the order customer selection screen.")
    }
}


private struct OrderCustomerSectionContent: View {

    /// View model to drive the view content
    var viewModel: EditableOrderViewModel.CustomerDataViewModel

    @Binding var showAddressForm: Bool

    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HStack(alignment: .top) {
                if viewModel.isDataAvailable {
                    Text(Localization.customer)
                        .accessibilityAddTraits(.isHeader)
                        .headlineStyle()
                    Spacer()

                    PencilEditButton() {
                        showAddressForm.toggle()
                    }
                    .accessibilityLabel(Text(Localization.editButtonAccessibilityLabel))
                }
            }
            .padding([.leading, .top, .trailing])
            .renderedIf(viewModel.isDataAvailable)

            if !viewModel.isDataAvailable {
                createCustomerView
                    .frame(minHeight: Layout.buttonHeight)
            } else {
                customerDataView
            }
        }
        .padding(.horizontal, insets: safeAreaInsets)
        .background(Color(.listForeground(modal: true)))
    }

    private var createCustomerView: some View {
        Button(Localization.addCustomerDetails) {
            showAddressForm.toggle()
        }
        .buttonStyle(PlusButtonStyle())
        .padding([.leading, .trailing])
    }

    private var customerDataView: some View {
        Group {
            addressDetails(title: Localization.billingTitle, formattedAddress: viewModel.billingAddressFormatted)
            Divider()
                .padding(.leading)
            addressDetails(title: Localization.shippingTitle, formattedAddress: viewModel.shippingAddressFormatted)

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
        .accessibilityElement(children: .combine)
        .padding()
    }
}

// MARK: Constants
private extension OrderCustomerSectionContent {
    enum Layout {
        static let verticalHeadlineSpacing: CGFloat = 22.0
        static let verticalEmailSpacing: CGFloat = 4.0
        static let verticalAddressSpacing: CGFloat = 6.0
        static let buttonHeight: CGFloat = 56.0
    }

    enum Localization {
        static let customer = NSLocalizedString("Customer", comment: "Title text of the section that shows Customer details when creating a new order")
        static let addCustomerDetails = NSLocalizedString("Add Customer Details",
                                                          comment: "Title text of the button that adds customer data when creating a new order")
        static let editButtonAccessibilityLabel = NSLocalizedString(
            "Edit Customer Details",
            comment: "Accessibility label for the button to edit customer details on the New Order screen"
        )

        static let billingTitle = NSLocalizedString("Billing Address", comment: "Title for the Billing Address section in order customer data")
        static let shippingTitle = NSLocalizedString("Shipping Address", comment: "Title for the Edit Shipping Address section in order customer data")

        static let noAddress = NSLocalizedString("No address specified.", comment: "Placeholder for empty address in order customer data")
    }
}

struct LegacyOrderCustomerSection_Previews: PreviewProvider {
    static var previews: some View {
        let emptyViewModel = EditableOrderViewModel.CustomerDataViewModel(billingAddress: nil, shippingAddress: nil)
        let addressViewModel = EditableOrderViewModel.CustomerDataViewModel(fullName: "Johnny Appleseed",
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
