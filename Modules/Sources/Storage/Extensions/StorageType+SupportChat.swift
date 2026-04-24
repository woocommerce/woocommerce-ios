import Foundation

// MARK: - StoredSupportChat helpers
//
public extension StorageType {

    /// Returns the single `StoredSupportChat` with the given `chatID`, if any.
    ///
    func loadSupportChat(chatID: Int64) -> StoredSupportChat? {
        let predicate = NSPredicate(format: "chatID == %lld", chatID)
        return firstObject(ofType: StoredSupportChat.self, matching: predicate)
    }

    /// Returns the `StoredSupportChat` entries for a site, newest first.
    ///
    func loadSupportChats(siteID: Int64) -> [StoredSupportChat] {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(key: "updatedAt", ascending: false)
        return allObjects(ofType: StoredSupportChat.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Deletes the `StoredSupportChat` with the given `chatID`, if present.
    ///
    func deleteSupportChat(chatID: Int64) {
        guard let chat = loadSupportChat(chatID: chatID) else {
            return
        }
        deleteObject(chat)
    }
}
