import Foundation
import Storage

// MARK: - ListItemType: Represents an Entity that cannot be modified and simplified to display on a list.
//
public protocol ListItemType {}

// MARK: - Represents a Mutable Entity that can be converted into a ListItem Type.
//
public protocol ListItemConvertible {

    /// Represents the ReadOnly Type (mirroring the receiver).
    ///
    associatedtype ListItemType

    /// Updates the Receiver with the ReadOnly Instance.
    ///
    func update(with entity: ListItemType)

    /// Returns a ListItem version of the receiver.
    ///
    func toListItem() -> ListItemType
}
