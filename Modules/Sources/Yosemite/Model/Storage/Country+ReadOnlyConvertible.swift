import Foundation
import Storage


// MARK: - Storage.Country: ReadOnlyConvertible
//
extension Storage.Country: ReadOnlyConvertible {

    /// Updates the Storage.Country with the ReadOnly.
    ///
    public func update(with country: Yosemite.Country) {
        code = country.code
        name = country.name
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.Country {
        return Country(code: code,
                       name: name,
                       states: states.map { $0.toReadOnly() })
    }
}
