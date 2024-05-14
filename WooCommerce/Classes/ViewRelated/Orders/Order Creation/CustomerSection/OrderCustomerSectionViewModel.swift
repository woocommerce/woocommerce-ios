import SwiftUI
import Yosemite

/// View model for `OrderCustomerSection` view.
/// As it holds states for the UI like the search modal visibility, this view model is designed to be the same instance throughout the life time of the order form.
final class OrderCustomerSectionViewModel: ObservableObject {
    let siteID: Int64
    let isCustomerAccountRequired: Bool
    let isEditable: Bool

    // MARK: - Customer search
    @Published var showsCustomerSearch: Bool = false
    @Published var customerData: CollapsibleCustomerCardViewModel.CustomerData
    @Published var addressFormViewModel: CreateOrderAddressFormViewModel
    private let updateCustomer: (Customer?) -> Void

    // MARK: - Address
    @Published var showsAddressForm: Bool = false
    let resetAddressForm: () -> Void

    @Published private(set) var cardViewModel: CollapsibleCustomerCardViewModel?

    init(siteID: Int64,
         addressFormViewModel: CreateOrderAddressFormViewModel,
         customerData: CollapsibleCustomerCardViewModel.CustomerData,
         isCustomerAccountRequired: Bool,
         isEditable: Bool,
         updateCustomer: @escaping (Customer?) -> Void,
         resetAddressForm: @escaping () -> Void) {
        self.siteID = siteID
        self.addressFormViewModel = addressFormViewModel
        self.customerData = customerData
        self.isCustomerAccountRequired = isCustomerAccountRequired
        self.isEditable = isEditable
        self.updateCustomer = updateCustomer
        self.resetAddressForm = resetAddressForm
        observeCustomerDataForCardViewModel()
    }

    /// Called when the user taps to add customer details.
    func addCustomerDetails() {
        cardViewModel = .init(customerData: customerData,
                              isCustomerAccountRequired: isCustomerAccountRequired,
                              isEditable: isEditable,
                              isCollapsed: false,
                              removeCustomer: removeCustomer,
                              editAddress: editAddress)
    }

    /// Called when the user taps to search for a customer.
    func searchCustomer() {
        showsCustomerSearch = true
    }

    /// Called when the user selects a customer from search.
    func addCustomerFromSearch(_ customer: Customer) {
        updateCustomer(customer)
    }
}

private extension OrderCustomerSectionViewModel {
    func removeCustomer() {
        updateCustomer(nil)
    }

    func editAddress() {
        showsAddressForm = true
    }
}

private extension OrderCustomerSectionViewModel {
    func observeCustomerDataForCardViewModel() {
        $customerData
            .compactMap { [weak self] customerData in
                guard let self, customerData.email?.isNotEmpty == true || customerData.shippingAddressFormatted?.isNotEmpty == true else {
                    return nil
                }
                return CollapsibleCustomerCardViewModel(customerData: customerData,
                                                        isCustomerAccountRequired: isCustomerAccountRequired,
                                                        isEditable: isEditable,
                                                        isCollapsed: true,
                                                        removeCustomer: removeCustomer,
                                                        editAddress: editAddress)
            }
            .assign(to: &$cardViewModel)
    }
}
