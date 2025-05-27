import Foundation
@testable import Yosemite

final class MockPOSItemFetchAnalyticsTracking: POSItemFetchAnalyticsTracking {
    private(set) var spyTotalItems: Int?
    private(set) var spyMillisecondsSinceRequestSent: Int?
    private(set) var spySearchTotalItems: Int?

    func trackItemsFetchComplete(totalItems: Int) {
        spyTotalItems = totalItems
    }

    func trackSearchRemoteResultsFetchComplete(millisecondsSinceRequestSent: Int, totalItems: Int) {
        spyMillisecondsSinceRequestSent = millisecondsSinceRequestSent
        spySearchTotalItems = totalItems
    }
}
