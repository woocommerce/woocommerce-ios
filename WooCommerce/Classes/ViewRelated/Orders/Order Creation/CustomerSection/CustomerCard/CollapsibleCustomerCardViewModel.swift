import SwiftUI

/// View model for `CollapsibleCustomerCard` view.
final class CollapsibleCustomerCardViewModel: ObservableObject {
    struct CustomerData {
        let email: String?
        let fullName: String?
        let billingAddressFormatted: String?
        let shippingAddressFormatted: String?
    }

    let isCustomerAccountRequired: Bool
    let isEditable: Bool
    let emailPlaceholder: String

    @Published var isCollapsed: Bool

    @Published var email: String

    var shippingAddress: String? {
        [originalCustomerData.fullName, originalCustomerData.shippingAddressFormatted].compactMap { $0 }
            .filter { $0.isNotEmpty }
            .joined(separator: "\n")
    }

    init(customerData: CustomerData,
         isCustomerAccountRequired: Bool,
         isEditable: Bool,
         isCollapsed: Bool) {
        self.isCustomerAccountRequired = isCustomerAccountRequired
        self.isEditable = isEditable
        self.isCollapsed = isCollapsed
        self.emailPlaceholder = Localization.emailPlaceholder(isRequired: isCustomerAccountRequired)
        self.email = customerData.email ?? ""
    }
}

private extension CollapsibleCustomerCardViewModel {
    enum Localization {
        static func emailPlaceholder(isRequired: Bool) -> String {
            isRequired ? emailPlaceholderRequired: emailPlaceholderNotRequired
        }

        static let emailPlaceholderRequired = NSLocalizedString(
            "orderForm.customerSection.customerCard.header.emailPlaceholder.required",
            value: "Email address required",
            comment: "Placeholder of the email in the header of a customer card in order form when an account is required."
        )
        static let emailPlaceholderNotRequired = NSLocalizedString(
            "orderForm.customerSection.customerCard.header.emailPlaceholder.notRequired",
            value: "Email address",
            comment: "Placeholder of the email in the header of a customer card in order form when an account is not required."
        )
    }
}
