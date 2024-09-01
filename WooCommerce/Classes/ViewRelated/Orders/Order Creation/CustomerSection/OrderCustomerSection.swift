import SwiftUI

struct OrderCustomerSection: View {
    @ObservedObject var viewModel: OrderCustomerSectionViewModel

    var body: some View {
        Group {
            if let cardViewModel = viewModel.cardViewModel {
                VStack(alignment: .leading, spacing: Layout.spacingBetweenHeaderAndCard) {
                    HStack {
                        Text(Localization.customerHeader)
                            .headlineStyle()
                        Spacer()
                        searchCustomerView
                    }

                    CollapsibleCustomerCard(viewModel: cardViewModel)
                }
                .padding()
            } else {
                createCustomerView
                    .frame(minHeight: Layout.buttonHeight)
            }
        }
        .background(Color(.listForeground(modal: true)))
        .sheet(isPresented: $viewModel.showsCustomerSearch) {
            NavigationView {
                CustomerSelectorView(
                    siteID: viewModel.siteID,
                    configuration: CustomerSelectorViewController.Configuration(
                        title: Localization.customerSelectorTitle,
                        disallowSelectingGuest: viewModel.isCustomerAccountRequired,
                        disallowCreatingCustomer: true,
                        showGuestLabel: false,
                        shouldTrackCustomerAdded: true
                    ),
                    addressFormViewModel: viewModel.addressFormViewModel) { customer in
                        viewModel.addCustomerFromSearch(customer)
                    }
            }
        }
        .sheet(isPresented: $viewModel.showsAddressForm) {
            NavigationView {
                EditOrderAddressForm(dismiss: { _ in
                    viewModel.showsAddressForm.toggle()
                },
                                     viewModel: viewModel.addressFormViewModel)
            }
            .discardChangesPrompt(canDismiss: !viewModel.addressFormViewModel.hasPendingChanges,
                                  didDismiss: viewModel.addressFormViewModel.userDidCancelFlow)
            .onDisappear {
                viewModel.resetAddressForm()
            }
        }
    }

    private var createCustomerView: some View {
        Button(Localization.addCustomerDetails) {
            viewModel.addCustomerDetails()
        }
        .buttonStyle(PlusButtonStyle())
        .padding([.leading, .trailing])
    }

    private var searchCustomerView: some View {
        Button(action: {
            viewModel.searchCustomer()
        }, label: {
            Image(systemName: "magnifyingglass")
        })
        .buttonStyle(TextButtonStyle())
        .accessibilityLabel(Localization.searchCustomerAccessibilityLabel)
    }
}

// MARK: Constants
private extension OrderCustomerSection {
    enum Layout {
        static let buttonHeight: CGFloat = 56.0
        static let spacingBetweenHeaderAndCard: CGFloat = 16
    }

    enum Localization {
        static let addCustomerDetails = NSLocalizedString("orderForm.customerSection.addCustomer",
                                                          value: "Add Customer",
                                                          comment: "Title text of the button that adds customer data in the order form.")
        static let customerHeader = NSLocalizedString("orderForm.customerSection.customerHeader",
                                                      value: "Customer",
                                                      comment: "Header text of the customer card in the order form.")
        static let customerSelectorTitle = NSLocalizedString(
            "orderForm.customerSection.customerSelectorTitle",
            value: "Add customer details",
            comment: "Title of the order customer selection screen in the order form.."
        )
        static let searchCustomerAccessibilityLabel = NSLocalizedString(
            "customer.search.button.accessibilityLabel",
            value: "Search customer",
            comment: "Accessibility title for the search button on the customer section.")
    }
}

struct OrderCustomerSection_Previews: PreviewProvider {
    static let customer: CollapsibleCustomerCardViewModel.CustomerData = .init(
        customerID: 0,
        email: "customer@woo.com",
        fullName: "T Woo",
        billingAddressFormatted: "123 60th St\nUSA",
        shippingAddressFormatted: nil
    )
    static var previews: some View {
        Group {
            OrderCustomerSection(viewModel: .init(siteID: 1,
                                                  addressFormViewModel: .init(
                                                    siteID: 1,
                                                    addressData: .init(billingAddress: nil,
                                                                       shippingAddress: nil),
                                                    onAddressUpdate: nil
                                                  ),
                                                  customerData: customer,
                                                  isCustomerAccountRequired: true,
                                                  isEditable: true,
                                                  updateCustomer: { _ in },
                                                  resetAddressForm: {}))
            OrderCustomerSection(viewModel: .init(siteID: 1,
                                                  addressFormViewModel: .init(
                                                    siteID: 1,
                                                    addressData: .init(billingAddress: nil,
                                                                       shippingAddress: nil),
                                                    onAddressUpdate: nil
                                                  ),
                                                  customerData: customer,
                                                  isCustomerAccountRequired: false,
                                                  isEditable: true,
                                                  updateCustomer: { _ in },
                                                  resetAddressForm: {}))
        }
    }
}
