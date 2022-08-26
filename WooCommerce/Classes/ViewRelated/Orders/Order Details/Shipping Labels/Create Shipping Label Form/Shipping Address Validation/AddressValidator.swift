import Foundation

class AddressValidator {
    enum AddressValidationError: Error {
        case local
        case remote(Error)
    }
}
