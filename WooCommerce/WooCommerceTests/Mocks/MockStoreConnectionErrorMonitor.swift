import Combine
import Foundation
import Yosemite

/// MockStoreConnectionErrorMonitor: lets tests decide which store, if any, is unreachable.
///
/// Deliberately matches the real monitor on the two things a consumer can observe: changes are announced
/// on the main queue, and a value equal to the current one is not announced again.
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
        subject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    /// Simulates the networking layer flagging or clearing a store.
    ///
    func simulateAffectedSiteID(_ siteID: Int64?) {
        guard subject.value != siteID else {
            return
        }
        subject.send(siteID)
    }
}
