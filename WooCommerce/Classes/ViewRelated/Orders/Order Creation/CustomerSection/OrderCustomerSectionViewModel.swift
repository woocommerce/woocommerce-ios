import SwiftUI

/// View model for `OrderCustomerSection` view.
final class OrderCustomerSectionViewModel: ObservableObject {
    let isCustomerAccountRequired: Bool
    let isEditable: Bool
    @Published private(set) var cardViewModel: CollapsibleCustomerCardViewModel?
    private let customerData: CollapsibleCustomerCardViewModel.CustomerData

    init(customerData: CollapsibleCustomerCardViewModel.CustomerData,
         isCustomerAccountRequired: Bool,
         isEditable: Bool) {
        self.customerData = customerData
        self.isCustomerAccountRequired = isCustomerAccountRequired
        self.isEditable = isEditable
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
}
