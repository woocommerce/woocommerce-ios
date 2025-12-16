import protocol Yosemite.POSSearchHistoryProviding
import enum Yosemite.POSItemType

final class MockPOSSearchHistoryService: POSSearchHistoryProviding {
    var mockHistory: [String] = []
    var lastRequestedItemType: POSItemType?

    func saveSuccessfulSearch(term: String, for itemType: POSItemType) {}

    func searchHistory(for itemType: POSItemType) -> [String] {
        lastRequestedItemType = itemType
        return mockHistory
    }
}
