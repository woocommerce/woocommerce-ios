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
    /// - Parameter appVersion: the application version that we are looking for the translations
    /// - Parameter locale: the desired locale to get the translated texts
    /// - Parameter completion: A result that may contain an Announcement or an Error
    ///
    public func getAnnouncement(appId: String,
                                appVersion: String,
                                locale: String,
                                completion: @escaping (Result<StorageAnnouncement?, Error>) -> Void) {

        getAnnouncements(appId: appId, appVersion: appVersion, locale: locale) { [weak self] result in
            switch result {
            case .success(let announcements):
                guard let self = self,
                      let firstAnnouncement = announcements.first else {
                    return completion(.success(nil))
                }
                let announcement = self.mapAnnouncementToStorageModel(firstAnnouncement)
                completion(.success(announcement))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func mapAnnouncementToStorageModel(_ announcement: WordPressKit.Announcement) -> StorageAnnouncement {
        let mappedFeatures = announcement.features.map {
            Feature(title: $0.title,
                    subtitle: $0.subtitle,
                    iconUrl: $0.iconUrl,
                    iconBase64: $0.iconBase64)
        }

        return StorageAnnouncement(appVersion: announcement.appVersionName,
                                   features: mappedFeatures,
                                   announcementVersion: announcement.announcementVersion,
                                   displayed: false)
    }
}
