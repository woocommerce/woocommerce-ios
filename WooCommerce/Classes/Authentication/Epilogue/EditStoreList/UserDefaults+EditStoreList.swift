import Foundation

// MARK: - Edit store list helpers
//
extension UserDefaults {
    @objc dynamic var hiddenStoreIDs: [Int64] {
        array(forKey: Key.hiddenStoreIDs.rawValue) as? [Int64] ?? []
    }

    /// Saves objective ID for future Blaze campaigns
    ///
    func saveHiddenStoreIDs(_ ids: [Int64]) {
        self[.hiddenStoreIDs] = ids
    }

    /// Removes a single store from the hidden list, making it visible in the picker again.
    func unhideStoreID(_ storeID: Int64) {
        var ids = hiddenStoreIDs
        guard ids.contains(storeID) else { return }
        ids.removeAll { $0 == storeID }
        saveHiddenStoreIDs(ids)
    }
}
