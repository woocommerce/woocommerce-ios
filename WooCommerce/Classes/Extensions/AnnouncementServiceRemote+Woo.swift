import WordPressKit
import Storage
import Networking
import Yosemite

/// Makes AnnouncementServiceRemote from WordPressKit conform with AnnouncementsRemoteProtocol so we can inject other remotes. (For testing purposes)
extension AnnouncementServiceRemote: AnnouncementsRemoteProtocol {

    override convenience init() {
        self.init(wordPressComRestApi: WordPressComRestApi(baseUrlString: Settings.wordpressApiBaseURL))
    }

    /// Fetch announcements from WordPressKit announcements public API
    ///
    /// - Parameter appId: the application identifier. 4 stands for WooCommerce
    /// - Parameter appVersion: the application version that we are looking forbthe translations
    /// - Parameter completion: A result that may contain an Announcement or an Error
    ///
    public func getAnnouncement(appId: String,
                                appVersion: String,
                                locale: String,
                                completion: @escaping (Result<Storage.Announcement?, Error>) -> Void) {

        getAnnouncements(appId: appId, appVersion: appVersion, locale: locale) { result in
            switch result {
            case .success(let announcements):
                guard let firstAnnouncement = announcements.first else {
                    completion(.success(nil))
                    return
                }
                let announcement = self.mapAnnouncementToStorageModel(firstAnnouncement)
                completion(.success(announcement))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func mapAnnouncementToStorageModel(_ announcement: WordPressKit.Announcement) -> Storage.Announcement {
        let mappedFeatures = announcement.features.compactMap {
            Feature(title: $0.title, subtitle: $0.subtitle, iconUrl: $0.iconUrl)
        }

        return Storage.Announcement(appVersion: announcement.appVersionName, features: mappedFeatures)
    }
}
