import SwiftUI

/// Represents a field in a WooCommerce Shipping address.
final class WooShippingAddressField: ObservableObject {
    let type: WooShippingAddressFieldType

    /// The value to display for the field.
    @Published var value: String

    /// Whether the field is required.
    @Published var required: Bool

    /// The error message to display; set if the value is invalid.
    @Published private(set) var errorMessage: String? = nil

    /// Closure used to validate a new value for the field.
    /// Returns an error message if the value is invalid.
    var validate: (String) -> String?

    init(type: WooShippingAddressFieldType,
         value: String,
         required: Bool,
         validate: @escaping (String) -> String?) {
        self.type = type
        self.value = value
        self.required = required
        self.validate = validate

        observeValue()
    }

    private func observeValue() {
        $value
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { [weak self] newValue in
                self?.validate(newValue)
            }
            .assign(to: &$errorMessage)
    }

    /// Validates the field with the current value.
    func validateField() {
        errorMessage = validate(value)
    }

    /// Clears the current validation error.
    /// This can be used to reset an error for later re-validation.
    func clearError() {
        errorMessage = nil
    }
}

/// Represents the types of fields in a WooCommerce Shipping address.
enum WooShippingAddressFieldType: CaseIterable {
    case name
    case company
    case country
    case address
    case city
    case state
    case postalCode
    case email
    case phone
}
