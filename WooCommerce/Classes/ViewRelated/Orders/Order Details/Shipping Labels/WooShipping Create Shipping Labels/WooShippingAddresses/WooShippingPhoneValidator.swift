import Foundation

enum WooShippingPhoneValidator {
    static func digits(from phone: String) -> String {
        phone.components(separatedBy: .decimalDigits.inverted).joined()
    }

    static func isValid(phone: String, country: String?) -> Bool {
        guard phone.isNotEmpty else {
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
}
