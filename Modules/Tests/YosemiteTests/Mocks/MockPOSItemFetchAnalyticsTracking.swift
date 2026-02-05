import Foundation
@testable import Yosemite

final class MockPOSItemFetchAnalyticsTracking: POSItemFetchAnalyticsTracking {
    private(set) var spyTotalItems: Int?
    private(set) var spyMillisecondsSinceRequestSent: Int?
    private(set) var spySearchTotalItems: Int?
    private(set) var spyLocalSearchMilliseconds: Int?
    private(set) var spyLocalSearchTotalItems: Int?
    private(set) var spyLocalSearchMethod: String?
    private(set) var spyLocalSearchSource: String?

    func trackItemsFetchComplete(totalItems: Int) {
        spyTotalItems = totalItems
    }

    func trackSearchRemoteResultsFetchComplete(millisecondsSinceRequestSent: Int, totalItems: Int) {
        spyMillisecondsSinceRequestSent = millisecondsSinceRequestSent
        spySearchTotalItems = totalItems
    }

    func trackSearchLocalResultsFetchComplete(millisecondsSinceRequestSent: Int,
                                              totalItems: Int,
                                              searchMethod: String,
                                              source: String) {
        spyLocalSearchMilliseconds = millisecondsSinceRequestSent
        spyLocalSearchTotalItems = totalItems
        spyLocalSearchMethod = searchMethod
        spyLocalSearchSource = source
    }
}
