import Foundation
import Storage


// MARK: - Represents a Mutable Entity that can be converted into a ReadOnly Type.
//
public protocol ReadOnlyConvertible: class {

    /// Represents the ReadOnly Type (mirroring the receiver).
    ///
    associatedtype ReadOnlyType

    /// Updates the Receiver with the ReadOnly Instance.
    ///
    func update(with entity: ReadOnlyType)

    /// Returns a ReadOnly version of the receiver.
    ///
    func toReadOnly() -> ReadOnlyType
}
