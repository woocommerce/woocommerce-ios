import WordPressKit
import Storage
import Networking
import Yosemite

/// Makes AnnouncementServiceRemote from WordPressKit conform with AnnouncementsRemoteProtocol so we can inject other remotes. (For testing purposes)
extension AnnouncementServiceRemote: AnnouncementsRemoteProtocol {

    override convenience init() {
        self.init(wordPressComRestApi: WordPressComRestApi(baseUrlString: Settings.wordpressApiBaseURL))
    }

    /// Fetch features from WordPressKit announcements public API
    ///
    /// - Parameter appId: the application identifier. 4 stands for WooCommerce
    /// - Parameter appVersion: the application version that we are looking for
    /// - Parameter locale: the locale that will be used for the translations
    /// - Parameter completion: A result that may contain a list of WooCommerceFeature or an Error
    ///
    public func getFeatures(appId: String,
                            appVersion: String,
                            locale: String,
                            completion: @escaping (Result<[Storage.Feature], Error>) -> Void) {

        getAnnouncements(appId: appId, appVersion: appVersion, locale: locale) { result in
            switch result {
            case .success(let announcements):
                let mappedFeatures = announcements.first?.features.compactMap {
                    Feature(title: $0.title, subtitle: $0.subtitle, iconUrl: $0.iconUrl)
                } ?? []
                completion(.success(mappedFeatures))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
