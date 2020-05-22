extension Note.Kind: Codable {}

/// The type of notification count for the site
public enum SiteNotificationCountType {
    /// The count for the specific kind
    case kind(Note.Kind)
    /// The count for all kinds of notifications
    case allKinds
}

/// A wrapper of a dictionary that maps from a site ID to a dictionary from notification type to count.
///
struct SiteNotificationCountFileContents: Codable, Equatable {
    let countBySite: [Int64: [Note.Kind: Int]]

    public init(countBySite: [Int64: [Note.Kind: Int]]) {
        self.countBySite = countBySite
    }
}

extension SiteNotificationCountFileContents {
    func notificationCount(siteID: Int64, type: SiteNotificationCountType) -> Int {
        guard let notificationCountByType = countBySite[siteID] else {
            return 0
        }

        switch type {
        case .kind(let kind):
            return notificationCountByType[kind] ?? 0
        case .allKinds:
            return notificationCountByType.values.reduce(0, +)
        }
    }
}
