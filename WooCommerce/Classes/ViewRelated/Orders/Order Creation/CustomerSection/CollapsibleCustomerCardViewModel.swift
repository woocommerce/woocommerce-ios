import SwiftUI

/// View model for `CollapsibleCustomerCard` view.
final class CollapsibleCustomerCardViewModel: ObservableObject {
    let isCustomerAccountRequired: Bool
    let isEditable: Bool

    @Published var isCollapsed: Bool

    init(isCustomerAccountRequired: Bool,
         isEditable: Bool,
         isCollapsed: Bool) {
        self.isCustomerAccountRequired = isCustomerAccountRequired
        self.isEditable = isEditable
        self.isCollapsed = isCollapsed
    }
}
