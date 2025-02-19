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
}
