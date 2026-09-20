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
    private let unexpectedStoreResponseSubject = CurrentValueSubject<Int64?, Never>(nil)

    init(affectedSiteID: Int64? = nil) {
        self.subject = CurrentValueSubject(affectedSiteID)
    }

    var affectedSiteID: Int64? {
        subject.value
    }

    var affectedSiteIDPublisher: AnyPublisher<Int64?, Never> {
        subject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    var unexpectedStoreResponsePublisher: AnyPublisher<Int64, Never> {
        unexpectedStoreResponseSubject
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func acknowledgeUnexpectedStoreResponse(siteID: Int64) {
        if unexpectedStoreResponseSubject.value == siteID {
            unexpectedStoreResponseSubject.send(nil)
        }
    }

    /// Simulates the networking layer reporting an unexpected response.
    ///
    func simulateUnexpectedStoreResponse(siteID: Int64) {
        unexpectedStoreResponseSubject.send(siteID)
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
