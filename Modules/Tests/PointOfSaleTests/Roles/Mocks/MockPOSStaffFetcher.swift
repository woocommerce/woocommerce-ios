import Foundation
import struct Networking.POSStaffMember
@testable import PointOfSale

/// Test stub. Safe under main-actor-isolated Swift Testing suites; not safe for concurrent access.
final class MockPOSStaffFetcher: POSStaffFetching, @unchecked Sendable {
    var results: [Result<[POSStaffMember], POSStaffFetchError>]
    private(set) var calls: Int = 0

    init(results: [Result<[POSStaffMember], POSStaffFetchError>]) {
        self.results = results
    }

    convenience init(staff: [POSStaffMember]) {
        self.init(results: [.success(staff)])
    }

    convenience init(error: POSStaffFetchError) {
        self.init(results: [.failure(error)])
    }

    func fetchStaff(siteID: Int64) async throws(POSStaffFetchError) -> [POSStaffMember] {
        defer { calls += 1 }
        let result = results[min(calls, results.count - 1)]
        switch result {
        case .success(let staff): return staff
        case .failure(let error): throw error
        }
    }
}
