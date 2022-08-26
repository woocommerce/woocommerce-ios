import Yosemite

class AddressValidator {
    let address: ShippingLabelAddress?
    let onlyLocally: Bool
    let nameRequired: Bool
    let phoneNumberRequired: Bool
    let stateOfCountryRequired: Bool
    let onCompletion: (Result<Void, AddressValidationError>) -> Void

    init(address: ShippingLabelAddress?,
         onlyLocally: Bool,
         nameRequired: Bool = false,
         phoneNumberRequired: Bool = false,
         stateOfCountryRequired: Bool = false,
         onCompletion: @escaping (Result<Void, AddressValidationError>) -> Void) {
        self.address = address
        self.onlyLocally = onlyLocally
        self.nameRequired = nameRequired
        self.phoneNumberRequired = phoneNumberRequired
        self.stateOfCountryRequired = stateOfCountryRequired
        self.onCompletion = onCompletion
    }

    init(address: Address,
         onlyLocally: Bool,
         nameRequired: Bool = false,
         phoneNumberRequired: Bool = false,
         stateOfCountryRequired: Bool = false,
         onCompletion: @escaping (Result<Void, AddressValidationError>) -> Void) {
        self.onlyLocally = onlyLocally
        self.nameRequired = nameRequired
        self.phoneNumberRequired = phoneNumberRequired
        self.stateOfCountryRequired = stateOfCountryRequired
        self.onCompletion = onCompletion
        self.address = ShippingLabelAddress(company: address.company ?? "",
                                            name: address.firstName,
                                            phone: address.phone ?? "",
                                            country: address.country,
                                            state: address.state,
                                            address1: address.address1 ,
                                            address2: address.address2 ?? "",
                                            city: address.city,
                                            postcode: address.postcode)
    }

    private func validate(address: ShippingLabelAddress,
                  onlyLocally: Bool,
                  nameRequired: Bool = false,
                  completion: @escaping (Result<Void, AddressValidationError>) -> Void) {
        if validateAddressLocally().isNotEmpty {
            completion(.failure(.local))
            return
        }

        if onlyLocally {
            completion(.success(()))
            return
        }
    }

    private func validateAddressLocally() -> [LocalValidationError] {
        var errors: [LocalValidationError] = []

        if let addressToBeValidated = address {
            if addressToBeValidated.name.isEmpty && nameRequired {
                errors.append(.name)
            }
            if addressToBeValidated.address1.isEmpty {
                errors.append(.address)
            }
            if addressToBeValidated.city.isEmpty {
                errors.append(.city)
            }
            if addressToBeValidated.postcode.isEmpty {
                errors.append(.postcode)
            }
            if addressToBeValidated.state.isEmpty && stateOfCountryRequired {
                errors.append(.state)
            }
            if addressToBeValidated.country.isEmpty {
                errors.append(.country)
            }
            //TODO: validate phone number
        }

        return errors
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
