@testable import WooCommerce
import Combine
import Yosemite

struct MockStoreCreationStatusChecker: StoreCreationStatusChecker {
    private let siteSubject = PassthroughSubject<Site, Error>()

    func waitForSiteToBeReady(siteID: Int64) -> AnyPublisher<Yosemite.Site, Error> {
        siteSubject.eraseToAnyPublisher()
    }
}

extension MockStoreCreationStatusChecker {
    func markSiteAsReady(site: Site) {
        siteSubject.send(site)
    }
}
