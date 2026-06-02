import Foundation
@testable import PointOfSale
import struct Networking.POSStaffMember

final class MockPOSStaffFetcher: POSStaffFetching {
    var result: Result<[POSStaffMember], POSStaffFetchError>

    init(result: Result<[POSStaffMember], POSStaffFetchError> = .success([])) {
        self.result = result
    }

    func fetchStaff(siteID: Int64) async throws(POSStaffFetchError) -> [POSStaffMember] {
        try result.get()
    }
}
