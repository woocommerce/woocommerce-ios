import SwiftUI

/// View model for `OrderCustomerSection` view.
final class OrderCustomerSectionViewModel: ObservableObject {
    let isCustomerAccountRequired: Bool
    let isEditable: Bool
    @Published private(set) var cardViewModel: CollapsibleCustomerCardViewModel?

    init(isCustomerAccountRequired: Bool,
         isEditable: Bool) {
        self.isCustomerAccountRequired = isCustomerAccountRequired
        self.isEditable = isEditable
    }

    /// Called when the user taps to add customer details.
    func addCustomerDetails() {
        cardViewModel = .init(isCustomerAccountRequired: isCustomerAccountRequired, isEditable: isEditable, isCollapsed: false)
    }
}
