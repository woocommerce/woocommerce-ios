import Yosemite

/// Reusable implementation of the Address validation introduced by the
/// `ShippingLabelAddressFormViewModel`, but striped of the specifics to serve the form UI
/// 
class AddressValidator {
    let siteID: Int64
    private let stores: StoresManager

    init(siteID: Int64, stores: StoresManager) {
        self.siteID = siteID
        self.stores = stores
    }

    func validate(address: Address, onlyLocally: Bool, onCompletion: @escaping (Result<Void, AddressValidationError>) -> Void) {
        let convertedAddress = ShippingLabelAddress(company: address.company ?? "",
                                                    name: address.fullName,
                                                    phone: address.phone ?? "",
                                                    country: address.country,
                                                    state: address.state,
                                                    address1: address.address1 ,
                                                    address2: address.address2 ?? "",
                                                    city: address.city,
                                                    postcode: address.postcode)

        let localErrors = validateAddressLocally(addressToBeValidated: convertedAddress)
        if localErrors.isNotEmpty {
            let localErrorMessage = localErrors.map { $0.rawValue }.joined(separator: ", ")
            onCompletion(.failure(.local(localErrorMessage)))
            return
        }

        if onlyLocally {
            onCompletion(.success(()))
            return
        }

        let addressToBeVerified = ShippingLabelAddressVerification(address: convertedAddress, type: .destination)
        let action = ShippingLabelAction.validateAddress(siteID: siteID, address: addressToBeVerified) { result in
            switch result {
            case .success:
                onCompletion(.success(()))
            case .failure(let error):
                onCompletion(.failure(.remote(error as? ShippingLabelAddressValidationError)))
            }
        }
        stores.dispatch(action)
    }

    private func validateAddressLocally(addressToBeValidated: ShippingLabelAddress) -> [LocalValidationError] {
        var errors: [LocalValidationError] = []

        if addressToBeValidated.name.isEmpty && addressToBeValidated.company.isEmpty {
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

        return errors
    }

    enum LocalValidationError: String {
        case name = "Customer name and company are empty"
        case address = "Address is empty"
        case city = "City is empty"
        case postcode = "Postcode is empty"
        case state = "State is empty"
        case country = "Country is empty"
    }

    enum AddressValidationError: Error {
        case local(String)
        case remote(ShippingLabelAddressValidationError?)
    }
}
