import Foundation

/// `Announcement` remote endpoints.
///
public final class AnnouncementsRemote: Remote {

    /// Retrieves all the `Announcement` available for a given `siteID`
    ///
    public func loadAnnouncements(appVersion: String,
                                  locale: String,
                                  onCompletion: @escaping (Result<[Announcement], Error>) -> ()) {
        let parameters: [String: Any] = [
            Key.appID: Constants.WooCommerceAppId,
            Key.appVersion: appVersion,
            Key.locale: locale
        ]
        let request = DotcomRequest(wordpressApiVersion: .wpcomMark2,
                                    method: .get,
                                    path: Path.announcements,
                                    parameters: parameters)
        let mapper = AnnouncementListMapper()
        enqueue(request, mapper: mapper, completion: onCompletion)
    }
}

// MARK: - Constants
//
private extension AnnouncementsRemote {
    enum Key {
        static let appID = "app_id"
        static let appVersion = "app_version"
        static let locale = "_locale"
    }

    enum Path {
        static let announcements = "mobile/feature-announcements/"
    }

    enum Constants {
        static let WooCommerceAppId = "4"
    }
}
