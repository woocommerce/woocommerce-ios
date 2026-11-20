import Foundation
import Synchronization
@testable import PointOfSale

final class MockPOSPINClock: POSPINClock, Sendable {
    private let value = Mutex<TimeInterval>(1000)

    var seconds: TimeInterval {
        get { value.withLock { $0 } }
        set { value.withLock { $0 = newValue } }
    }

    func now() throws -> TimeInterval { seconds }
}
