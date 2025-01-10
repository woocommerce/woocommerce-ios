import SwiftUI

/// View model for editing an address in the Woo Shipping label flow.
final class WooShippingEditAddressViewModel: ObservableObject {
    @Published var name: String
    @Published var company: String
    @Published var country: String
    @Published var address: String
    @Published var city: String
    @Published var state: String
    @Published var postalCode: String
    @Published var email: String
    @Published var phone: String
    @Published var saveAsDefault: Bool

    /// Whether to show the company field by default.
    @Published var showCompanyField: Bool

    init(name: String,
         company: String,
         country: String,
         address: String,
         city: String,
         state: String,
         postalCode: String,
         email: String,
         phone: String,
         saveAsDefault: Bool,
         showCompanyField: Bool) {
        self.name = name
        self.company = company
        self.country = country
        self.address = address
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.email = email
        self.phone = phone
        self.saveAsDefault = saveAsDefault
        self.showCompanyField = showCompanyField
    }
}
