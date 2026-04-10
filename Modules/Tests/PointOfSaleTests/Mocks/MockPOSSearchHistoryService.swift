import protocol Yosemite.POSSearchHistoryProviding
import enum Yosemite.POSItemType

struct MockPOSSearchHistoryService: POSSearchHistoryProviding {
    func saveSuccessfulSearch(term: String, for itemType: POSItemType) {}

    func searchHistory(for itemType: POSItemType) -> [String] {
        return []
    }
}
