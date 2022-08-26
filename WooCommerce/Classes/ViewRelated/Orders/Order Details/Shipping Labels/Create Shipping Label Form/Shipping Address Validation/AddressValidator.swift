import Yosemite

class AddressValidator {
    func validate(address: ShippingLabelAddress,
                  onlyLocally: Bool,
                  completion: @escaping (Result<Void, AddressValidationError>) -> Void) {

    }

    func validate(address: Address,
                  onlyLocally: Bool,
                  completion: @escaping (Result<Void, AddressValidationError>) -> Void) {

    }

    enum ValidationType {
        case none
        case local
        case remote
    }

    enum LocalValidationError {
        case name
        case address
        case city
        case postcode
        case state
        case country
        case missingPhoneNumber
        case invalidPhoneNumber
    }

    enum AddressValidationError: Error {
        case local
        case remote(Error)
    }
}
