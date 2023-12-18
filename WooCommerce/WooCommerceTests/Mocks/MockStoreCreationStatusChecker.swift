@testable import WooCommerce
import Combine
import Yosemite

struct MockStoreCreationStatusChecker: StoreCreationStatusChecker {
    private let siteSubject: CurrentValueSubject<Site, Error>

    init(site: Site) {
        siteSubject = CurrentValueSubject<Site, Error>(site)
    }

    func waitForSiteToBeReady(siteID: Int64) -> AnyPublisher<Yosemite.Site, Error> {
        siteSubject.eraseToAnyPublisher()
    }
}
