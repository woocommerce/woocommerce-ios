import WordPressKit
import Storage
import Yosemite

/// Makes AnnouncementServiceRemote from WordPressKit conform with AnnouncementsRemoteProtocol so we can inject other remotes. (For testing purposes)
extension AnnouncementServiceRemote: AnnouncementsRemoteProtocol {

    public func getFeatures(appId: String,
                            appVersion: String,
                            locale: String,
                            completion: @escaping (Result<[WooCommerceFeature], Error>) -> Void) {

        getAnnouncements(appId: appId, appVersion: appVersion, locale: locale) { result in
            switch result {
            case .success(let announcements):
                let mappedFeatures = announcements.first?.features.compactMap {
                    WooCommerceFeature(title: $0.title, subtitle: $0.subtitle, iconUrl: $0.iconUrl)
                } ?? []
                completion(.success(mappedFeatures))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
