import Foundation
import Storage


// MARK: - Storage.StateOfAWooCountry: ReadOnlyConvertible
//
extension Storage.StateOfAWooCountry: ReadOnlyConvertible {

    /// Updates the Storage.StateOfAWooCountry with the ReadOnly.
    ///
    public func update(with stateOfACountry: Yosemite.StateOfAWooCountry) {
        code = stateOfACountry.code
        name = stateOfACountry.name
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.StateOfAWooCountry {
        return StateOfAWooCountry(code: code,
                                  name: name)
    }
}
