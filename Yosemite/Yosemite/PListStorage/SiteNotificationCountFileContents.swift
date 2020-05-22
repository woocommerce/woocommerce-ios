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

    func incrementing(siteID: Int64, type: Note.Kind, incrementCount: Int) -> SiteNotificationCountFileContents {
        var countBySite = self.countBySite
        if let existingNotificationCountByType = countBySite[siteID] {
            let newCount = (existingNotificationCountByType[type] ?? 0) + incrementCount
            countBySite[siteID]?[type] = newCount
        } else {
            countBySite[siteID] = [type: incrementCount]
        }
        return SiteNotificationCountFileContents(countBySite: countBySite)
    }

    func resetting(siteID: Int64, type: Note.Kind) -> SiteNotificationCountFileContents {
        var countBySite = self.countBySite
        countBySite[siteID]?[type] = 0
        return SiteNotificationCountFileContents(countBySite: countBySite)
    }
}
