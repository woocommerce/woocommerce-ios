import Foundation
import Storage


// MARK: - Storage.WooCountry: ReadOnlyConvertible
//
extension Storage.WooCountry: ReadOnlyConvertible {

    /// Updates the Storage.WooCountry with the ReadOnly.
    ///
    public func update(with country: Yosemite.WooCountry) {
        code = country.code
        name = country.name
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.WooCountry {
        return WooCountry(code: code,
                          name: name,
                          states: states.map { $0.toReadOnly() })
    }
}
