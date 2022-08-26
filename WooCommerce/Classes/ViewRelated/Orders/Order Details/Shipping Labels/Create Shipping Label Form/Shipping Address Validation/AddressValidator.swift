import Yosemite

class AddressValidator {
    func validate(address: ShippingLabelAddress,
                  onlyLocally: Bool,
                  completion: @escaping (Result<Void, AddressValidationError>) -> Void) {

    }

    func validate(address: Address,
                  onlyLocally: Bool,
                  completion: @escaping (Result<Void, AddressValidationError>) -> Void) {
        return validate(address: convertAddress(address: address), onlyLocally: onlyLocally, completion: completion)
    }

    private func convertAddress(address: Address) -> ShippingLabelAddress {
        ShippingLabelAddress(name: address.firstName,
                                    company: address.company,
                                    address1: address.address1,
                                    address2: address.address2,
                                    city: address.city,
                                    state: address.state,
                                    postcode: address.postcode,
                                    country: address.country,
                                    phone: address.phone,
                                    email: address.email)
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
