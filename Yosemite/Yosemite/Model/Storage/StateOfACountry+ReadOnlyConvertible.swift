import Foundation
import Storage


// MARK: - Storage.StateOfACountry: ReadOnlyConvertible
//
extension Storage.StateOfACountry: ReadOnlyConvertible {

    /// Updates the Storage.StateOfACountry with the ReadOnly.
    ///
    public func update(with stateOfACountry: Yosemite.StateOfACountry) {
        code = stateOfACountry.code
        name = stateOfACountry.name
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.StateOfACountry {
        return StateOfACountry(code: code,
                               name: name)
    }
}
