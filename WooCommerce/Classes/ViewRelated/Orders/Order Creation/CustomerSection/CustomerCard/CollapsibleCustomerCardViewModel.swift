import SwiftUI

/// View model for `CollapsibleCustomerCard` view.
final class CollapsibleCustomerCardViewModel: ObservableObject {
    struct CustomerData {
        let customerID: Int64?
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

    /// Whether the Remove Customer CTA can be shown.
    var canRemoveCustomer: Bool {
        (originalCustomerData.customerID ?? Constants.guestCustomerID) != Constants.guestCustomerID
    }

    /// Called when the user taps to remove customer.
    let removeCustomer: () -> Void

    private(set) lazy var addressViewModel: CollapsibleCustomerCardAddressViewModel = .init(
        billingAddressFormatted: originalCustomerData.billingAddressFormatted,
        shippingAddressFormatted: originalCustomerData.shippingAddressFormatted,
        editAddress: editAddress
    )
    /// Called when the user taps to add/edit address.
    private let editAddress: () -> Void

    private let originalCustomerData: CustomerData

    init(customerData: CustomerData,
         isCustomerAccountRequired: Bool,
         isEditable: Bool,
         isCollapsed: Bool,
         removeCustomer: @escaping () -> Void,
         editAddress: @escaping () -> Void) {
        self.isCustomerAccountRequired = isCustomerAccountRequired
        self.isEditable = isEditable
        self.isCollapsed = isCollapsed
        self.emailPlaceholder = Localization.emailPlaceholder(isRequired: isCustomerAccountRequired)
        self.email = customerData.email ?? ""
        self.originalCustomerData = customerData
        self.removeCustomer = removeCustomer
        self.editAddress = editAddress
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

    enum Constants {
        /// Order's customer ID is default to 0 based on the API doc:
        /// https://woocommerce.github.io/woocommerce-rest-api-docs/#order-properties
        static let guestCustomerID: Int64 = 0
    }
}
