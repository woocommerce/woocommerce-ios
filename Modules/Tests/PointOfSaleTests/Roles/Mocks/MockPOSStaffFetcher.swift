import Foundation
import Synchronization
@testable import PointOfSale
import struct Yosemite.POSStaffMember

/// Spy fetcher for tests.
final class MockPOSStaffFetcher: POSStaffFetching {
    private struct State {
        var result: Result<[POSStaffMember], POSStaffFetchError>
        var callCount = 0
        var onFetchStaff: (@Sendable () async -> Void)?
    }

    private let state: Mutex<State>

    var result: Result<[POSStaffMember], POSStaffFetchError> {
        get { state.withLock { $0.result } }
        set { state.withLock { $0.result = newValue } }
    }

    var callCount: Int {
        state.withLock { $0.callCount }
    }

    /// Runs inside `fetchStaff`, before it returns, so a test can mutate the SUT mid-fetch — e.g.
    /// simulate a logout (cache clear) landing while a staff fetch is in flight.
    var onFetchStaff: (@Sendable () async -> Void)? {
        get { state.withLock { $0.onFetchStaff } }
        set { state.withLock { $0.onFetchStaff = newValue } }
    }

    init(result: Result<[POSStaffMember], POSStaffFetchError> = .success([])) {
        self.state = Mutex(State(result: result))
    }

    func fetchStaff(siteID: Int64) async throws(POSStaffFetchError) -> [POSStaffMember] {
        let onFetchStaff = state.withLock {
            $0.callCount += 1
            return $0.onFetchStaff
        }
        await onFetchStaff?()
        return try result.get()
    }
}
