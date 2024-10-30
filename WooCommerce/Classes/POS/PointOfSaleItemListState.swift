import protocol Yosemite.POSItem

enum PointOfSaleItemListState: Equatable {
    case empty
    case initialLoading
    case loading
    case loaded([POSItem])
    case error(PointOfSaleErrorState)

    // Equatable conformance for testing:
    static func == (lhs: PointOfSaleItemListState, rhs: PointOfSaleItemListState) -> Bool {
        switch (lhs, rhs) {
        case (.initialLoading, .initialLoading),
            (.empty, .empty),
            (.loading, .loading):
            return true
        case (.loaded(let lhsItems), .loaded(let rhsItems)):
            return lhsItems.map { $0.itemID } == rhsItems.map { $0.itemID }
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}
