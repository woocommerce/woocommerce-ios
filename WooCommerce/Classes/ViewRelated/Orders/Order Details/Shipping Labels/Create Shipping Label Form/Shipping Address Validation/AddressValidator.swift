import Yosemite

class AddressValidator {
    let siteID: Int64
    private let stores: StoresManager

    init(siteID: Int64, stores: StoresManager) {
        self.siteID = siteID
        self.stores = stores
    }

    func validate(address: Address, onlyLocally: Bool, onCompletion: @escaping (Result<Void, AddressValidationError>) -> Void) {
        let convertedAddress = ShippingLabelAddress(company: address.company ?? "",
                                                    name: address.firstName,
                                                    phone: address.phone ?? "",
                                                    country: address.country,
                                                    state: address.state,
                                                    address1: address.address1 ,
                                                    address2: address.address2 ?? "",
                                                    city: address.city,
                                                    postcode: address.postcode)

        if validateAddressLocally(addressToBeValidated: convertedAddress).isNotEmpty {
            onCompletion(.failure(.local))
            return
        }

        if onlyLocally {
            onCompletion(.success(()))
            return
        }

        let addressToBeVerified = ShippingLabelAddressVerification(address: convertedAddress, type: .destination)
        let action = ShippingLabelAction.validateAddress(siteID: siteID, address: addressToBeVerified) { (result) in
            switch result {
            case .success:
                onCompletion(.success(()))
            case .failure(let error):
                onCompletion(.failure(.remote(error)))
            }
        }
        stores.dispatch(action)
    }

    private func validateAddressLocally(addressToBeValidated: ShippingLabelAddress) -> [LocalValidationError] {
        var errors: [LocalValidationError] = []

        if addressToBeValidated.name.isEmpty {
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
        if addressToBeValidated.state.isEmpty {
            errors.append(.state)
        }
        if addressToBeValidated.country.isEmpty {
            errors.append(.country)
        }
        if addressToBeValidated.phone.isEmpty {
            errors.append(.missingPhoneNumber)
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
