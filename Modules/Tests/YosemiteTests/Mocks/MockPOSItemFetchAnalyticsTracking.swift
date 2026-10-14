import Foundation
@testable import Yosemite

final class MockPOSItemFetchAnalyticsTracking: POSItemFetchAnalyticsTracking {
    private(set) var spyTotalItems: Int?
    private(set) var spyReturnedItemsCount: Int?
    private(set) var spyItemsFetchMilliseconds: Int?
    private(set) var spyMillisecondsSinceRequestSent: Int?
    private(set) var spySearchTotalItems: Int?
    private(set) var spyLocalSearchMilliseconds: Int?
    private(set) var spyLocalSearchTotalItems: Int?
    private(set) var spyLocalSearchMethod: POSSearchMethod?
    private(set) var spyLocalSearchSource: POSSearchSource?

    func trackItemsFetchComplete(totalItems: Int, returnedItemsCount: Int, millisecondsSinceRequestSent: Int) {
        spyTotalItems = totalItems
        spyReturnedItemsCount = returnedItemsCount
        spyItemsFetchMilliseconds = millisecondsSinceRequestSent
    }

    func trackSearchRemoteResultsFetchComplete(millisecondsSinceRequestSent: Int, totalItems: Int) {
        spyMillisecondsSinceRequestSent = millisecondsSinceRequestSent
        spySearchTotalItems = totalItems
    }

    func trackSearchLocalResultsFetchComplete(millisecondsSinceRequestSent: Int,
                                              totalItems: Int,
                                              searchMethod: POSSearchMethod,
                                              source: POSSearchSource) {
        spyLocalSearchMilliseconds = millisecondsSinceRequestSent
        spyLocalSearchTotalItems = totalItems
        spyLocalSearchMethod = searchMethod
        spyLocalSearchSource = source
    }
}
