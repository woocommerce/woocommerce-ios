import SwiftUI

/// View model for editing an address in the Woo Shipping label flow.
final class WooShippingEditAddressViewModel: ObservableObject, Identifiable {
    enum AddressType {
        case origin
        case destination
    }

    /// Type of address being edited.
    private let addressType: AddressType

    // MARK: Address properties

    let id: String
    @Published var name: String
    @Published var company: String
    @Published var country: String
    @Published var address: String
    @Published var city: String
    @Published var state: String
    @Published var postalCode: String
    @Published var email: String
    @Published var phone: String
    @Published var isDefault: Bool

    /// Whether to show the "save as default" toggle.
    var showSaveAsDefault: Bool {
        addressType == .origin
    }

    /// Whether to show the company field by default.
    @Published var showCompanyField: Bool

    // MARK: Local requirements & validation

    /// Whether the phone number is required.
    private let phoneNumberRequired: Bool

    // TODO: Set status based on initial verified status, whether any changes have been made, and local validation.
    /// Status of the address, based on local validation and remote verification.
    var status: WooShippingAddressStatus

    init(type: AddressType,
         id: String,
         name: String,
         company: String,
         country: String,
         address: String,
         city: String,
         state: String,
         postalCode: String,
         email: String,
         phone: String,
         isDefault: Bool,
         showCompanyField: Bool,
         isVerified: Bool,
         phoneNumberRequired: Bool) {
        self.addressType = type
        self.id = id
        self.name = name
        self.company = company
        self.country = country
        self.address = address
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.email = email
        self.phone = phone
        self.isDefault = isDefault
        self.showCompanyField = showCompanyField
        self.status = isVerified ? .verified : .unverified
        self.phoneNumberRequired = phoneNumberRequired
    }

    func isRequired(_ field: WooShippingEditAddressView.AddressField) -> Bool {
        switch field {
        case .name:
            return company.isEmpty
        case .company:
            return name.isEmpty
        case .country, .address, .city, .state, .postalCode, .email:
            return true
        case .phone:
            return phoneNumberRequired
        }
    }
}
