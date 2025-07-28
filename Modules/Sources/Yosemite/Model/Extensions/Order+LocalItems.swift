/// Simple type to serve negative IDs.
/// This is needed to differentiate if an item ID has been synced remotely while providing a unique ID to consumers.
/// If the ID is a negative number we assume that it's a local ID.
/// Warning: This is not thread safe.
///
public class LocalIDStore {
    /// Last used ID
    ///
    private var currentID: Int64 = 0

    /// Returns true if a given ID is deemed to be local(zero or negative).
    ///
    public static func isIDLocal(_ id: Int64) -> Bool {
        id <= 0
    }

    /// Creates a new and unique local ID for this session.
    ///
    public func dispatchLocalID() -> Int64 {
        currentID -= 1
        return currentID
    }

    public init() {}
}

// MARK: Order Helpers
public extension Order {
    /// Removes the `itemID`, `total` & `subtotal` values from local items.
    /// This is needed to:
    /// 1. Create the item without the local ID, the remote API would fail otherwise.
    /// 2. Let the remote source calculate the correct item price & total as it can vary depending on the store configuration. EG: `prices_include_tax` is set.
    ///
    func sanitizingLocalItems() -> Order {
        let sanitizedItems: [OrderItem] = items.map { item in
            guard LocalIDStore.isIDLocal(item.itemID) else {
                return item
            }
            return item.copy(itemID: .zero, subtotal: "", total: "")
        }
        return copy(items: sanitizedItems)
    }
}
