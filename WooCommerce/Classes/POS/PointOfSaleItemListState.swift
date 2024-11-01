import protocol Yosemite.POSItem

enum PointOfSaleItemListState: Equatable {
    case empty
    case initialLoading
    case loading(_ existingItems: [any POSDisplayableItem])
    case loaded([any POSDisplayableItem])
    case error(PointOfSaleErrorState)

    // Equatable conformance for testing:
    static func == (lhs: PointOfSaleItemListState, rhs: PointOfSaleItemListState) -> Bool {
        switch (lhs, rhs) {
        case (.initialLoading, .initialLoading),
            (.empty, .empty):
            return true
        case (.loading(let lhsItems), .loading(let rhsItems)),
            (.loaded(let lhsItems), .loaded(let rhsItems)):
            return true// lhsItems == rhsItems
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}
