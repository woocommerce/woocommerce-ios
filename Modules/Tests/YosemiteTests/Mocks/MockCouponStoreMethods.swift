import Foundation
@testable import Yosemite

final class MockCouponStoreMethods: CouponStoreMethodsProtocol {
    var synchronizeCalled = false
    var searchCalled = false
    var errorToThrow: NSError?

    var onSynchronizeCalled: () -> Void = {}

    nonisolated(nonsending) func synchronizeCoupons(siteID: Int64,
                            pageNumber: Int,
                            pageSize: Int) async throws -> Bool {
        synchronizeCalled = true
        onSynchronizeCalled()
        if let errorToThrow {
            throw errorToThrow
        }
        return true
    }

    nonisolated(nonsending) func searchCoupons(siteID: Int64,
                       keyword: String,
                       pageNumber: Int,
                       pageSize: Int) async throws {
        searchCalled = true
    }
}
