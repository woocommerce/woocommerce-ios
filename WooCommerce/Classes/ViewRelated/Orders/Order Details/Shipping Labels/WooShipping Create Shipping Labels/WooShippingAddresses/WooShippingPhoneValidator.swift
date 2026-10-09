import Foundation

enum WooShippingPhoneValidator {
    /// Why a phone number can't be used for a shipping label.
    enum Issue {
        /// The phone is empty, but the shipment needs one.
        case missing
        /// A phone was entered, but its format is invalid.
        case invalid
    }

    static func digits(from phone: String) -> String {
        phone.components(separatedBy: .decimalDigits.inverted).joined()
    }

    static func isValid(phone: String, country: String?) -> Bool {
        guard digits(from: phone).isNotEmpty else {
            return false
        }
        guard country == "US" else {
            return true
        }
        let phoneDigits = digits(from: phone)
        if phoneDigits.hasPrefix("1") {
            return phoneDigits.count == 11
        }
        return phoneDigits.count == 10
    }

    /// Whether the origin and destination countries differ, ignoring case. An unknown origin isn't international.
    static func isInternational(originCountry: String?, destinationCountry: String) -> Bool {
        guard let originCountry, originCountry.isNotEmpty else {
            return false
        }
        return originCountry.uppercased() != destinationCountry.uppercased()
    }

    /// The destination phone is required for international shipments and for FedEx services.
    static func isDestinationPhoneRequired(originCountry: String?, destinationCountry: String, carrierID: String?) -> Bool {
        isInternational(originCountry: originCountry, destinationCountry: destinationCountry)
            || carrierID == WooShippingCarrier.fedex.rawValue
    }

    /// Why the phone can't be used, or `nil` if it can.
    /// A phone that is empty after trimming is only an issue when required; an entered phone must pass `isValid`.
    static func issue(phone: String, country: String, isRequired: Bool) -> Issue? {
        guard phone.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty else {
            return isRequired ? .missing : nil
        }
        return isValid(phone: phone, country: country) ? nil : .invalid
    }
}
