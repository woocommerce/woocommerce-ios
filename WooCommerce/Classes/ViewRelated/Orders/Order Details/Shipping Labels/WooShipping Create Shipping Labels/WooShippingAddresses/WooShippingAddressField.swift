import SwiftUI

/// Represents a field in a WooCommerce Shipping address.
final class WooShippingAddressField: ObservableObject {
    let type: WooShippingAddressFieldType

    /// The value for the field.
    @Published var value: String

    /// An optional display value for the field.
    ///
    /// Set the display value with `setDisplayValue(_:)` for fields where the value is not suited for display.
    @Published private(set) var displayValue: String?

    /// Whether the field is required.
    @Published var required: Bool

    /// The error message to display; set if the value is invalid.
    @Published private(set) var errorMessage: String? = nil

    /// Closure used to validate a new value for the field.
    /// Returns an error message if the value is invalid.
    var validate: (String) -> String?

    /// Number of seconds to wait before validating new value input.
    private let validationDelay: Double

    init(type: WooShippingAddressFieldType,
         value: String,
         required: Bool,
         validationDelayInSeconds: Double = 1,
         validate: @escaping (String) -> String?) {
        self.type = type
        self.value = value
        self.required = required
        self.validationDelay = validationDelayInSeconds
        self.validate = validate

        observeValue()
    }

    private func observeValue() {
        $value
            .debounce(for: .seconds(validationDelay), scheduler: DispatchQueue.main)
            .map { [weak self] newValue in
                guard let self else { return nil }
                return validate(newValue)
            }
            .assign(to: &$errorMessage)
    }

    /// Sets the display value to the provided value.
    func setDisplayValue(_ value: String) {
        displayValue = value
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
