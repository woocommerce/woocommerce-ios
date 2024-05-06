import SwiftUI
import Yosemite

/// View model for `OrderCustomerSection` view.
final class OrderCustomerSectionViewModel: ObservableObject {
    let siteID: Int64
    let isCustomerAccountRequired: Bool
    let isEditable: Bool
    @Published var showsCustomerSearch: Bool = false
    @Published private(set) var cardViewModel: CollapsibleCustomerCardViewModel?
    @Published private(set) var addressFormViewModel: CreateOrderAddressFormViewModel
    private let customerData: CollapsibleCustomerCardViewModel.CustomerData
    private let addCustomer: (Customer) -> Void

    init(siteID: Int64,
         addressFormViewModel: CreateOrderAddressFormViewModel,
         customerData: CollapsibleCustomerCardViewModel.CustomerData,
         isCustomerAccountRequired: Bool,
         isEditable: Bool,
         addCustomer: @escaping (Customer) -> Void) {
        self.siteID = siteID
        self.addressFormViewModel = addressFormViewModel
        self.customerData = customerData
        self.isCustomerAccountRequired = isCustomerAccountRequired
        self.isEditable = isEditable
        self.addCustomer = addCustomer
        if customerData.email?.isNotEmpty == true || customerData.shippingAddressFormatted?.isNotEmpty == true {
            self.cardViewModel = .init(customerData: customerData,
                                       isCustomerAccountRequired: isCustomerAccountRequired,
                                       isEditable: isEditable,
                                       isCollapsed: true)
        }
    }

    /// Called when the user taps to add customer details.
    func addCustomerDetails() {
        cardViewModel = .init(customerData: customerData,
                              isCustomerAccountRequired: isCustomerAccountRequired,
                              isEditable: isEditable,
                              isCollapsed: false)
    }

    /// Called when the user taps to search for a customer.
    func searchCustomer() {
        showsCustomerSearch = true
    }

    /// Called when the user selects a customer from search.
    func addCustomerFromSearch(_ customer: Customer) {
        addCustomer(customer)
    }
}
