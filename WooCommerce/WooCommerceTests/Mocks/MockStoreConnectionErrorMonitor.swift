import Combine
import Foundation
import Yosemite

/// MockStoreConnectionErrorMonitor: lets tests decide which store, if any, is unreachable.
///
final class MockStoreConnectionErrorMonitor: StoreConnectionErrorMonitoring {
    private let subject: CurrentValueSubject<Int64?, Never>

    init(affectedSiteID: Int64? = nil) {
        self.subject = CurrentValueSubject(affectedSiteID)
    }

    var affectedSiteID: Int64? {
        subject.value
    }

    var affectedSiteIDPublisher: AnyPublisher<Int64?, Never> {
        subject.eraseToAnyPublisher()
    }

    /// Simulates the networking layer flagging or clearing a store.
    ///
    func simulateAffectedSiteID(_ siteID: Int64?) {
        subject.send(siteID)
    }
}
