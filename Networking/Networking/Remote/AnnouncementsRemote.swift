import Foundation

/// Protocol used to mock the remote.
///
public protocol AnnouncementsRemoteProtocol {
    func loadAnnouncements(appVersion: String,
                           locale: String,
                           onCompletion: @escaping (Result<[Announcement], Error>) -> Void)
}

/// `Announcement` remote endpoints.
///
public final class AnnouncementsRemote: Remote, AnnouncementsRemoteProtocol {

    /// Retrieves all the `Announcement` available for a given `appVersion` and `locale`
    ///
    public func loadAnnouncements(appVersion: String,
                                  locale: String,
                                  onCompletion: @escaping (Result<[Announcement], Error>) -> Void) {
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
        /// The requested appId. WooCommerce appID can be found here: PCYsg-sx0-p2
        static let WooCommerceAppId = "4"
    }
}
