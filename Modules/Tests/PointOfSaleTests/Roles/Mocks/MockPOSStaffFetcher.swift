import Foundation
@testable import PointOfSale
import struct Yosemite.POSStaffMember

/// Spy fetcher for tests.
final class MockPOSStaffFetcher: POSStaffFetching {
    var result: Result<[POSStaffMember], POSStaffFetchError>
    private(set) var callCount = 0

    /// Runs inside `fetchStaff`, before it returns, so a test can mutate the SUT mid-fetch — e.g.
    /// simulate a logout (cache clear) landing while a staff fetch is in flight.
    var onFetchStaff: (@Sendable () async -> Void)?

    init(result: Result<[POSStaffMember], POSStaffFetchError> = .success([])) {
        self.result = result
    }

    func fetchStaff(siteID: Int64) async throws(POSStaffFetchError) -> [POSStaffMember] {
        callCount += 1
        await onFetchStaff?()
        return try result.get()
    }
}
