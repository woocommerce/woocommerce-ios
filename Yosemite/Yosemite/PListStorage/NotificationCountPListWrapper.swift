extension Note.Kind: Codable {}

/// A wrapper of a dictionary that maps from a site ID to a dictionary from notification type to count.
///
struct NotificationCountPListWrapper: Codable, Equatable {
    let countBySite: [Int64: [Note.Kind: Int]]

    public init(countBySite: [Int64: [Note.Kind: Int]]) {
        self.countBySite = countBySite
    }
}

extension NotificationCountPListWrapper {
    func notificationCount(siteID: Int64, type: Note.Kind?) -> Int {
        guard let notificationCountByType = countBySite[siteID] else {
            return 0
        }

        if let type = type {
            return notificationCountByType[type] ?? 0
        } else {
            return notificationCountByType.values.reduce(0, +)
        }
    }
}
