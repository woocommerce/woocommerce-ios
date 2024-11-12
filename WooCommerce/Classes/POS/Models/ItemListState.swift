import protocol Yosemite.POSItem

enum ItemListState: Equatable {
    case empty
    case initialLoading
    case loading(_ currentItems: [POSItem])
    case loaded(_ items: [POSItem])
    case error(PointOfSaleErrorState)

    var isLoadingAfterInitialLoad: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }

    // Equatable conformance for testing:
    static func == (lhs: ItemListState, rhs: ItemListState) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty):
            return true
        case (.initialLoading, .initialLoading):
            return true
        case (.loading(let lhsItems), .loading(let rhsItems)),
            (.loaded(let lhsItems), .loaded(let rhsItems)):
            return lhsItems.map { $0.itemID } == rhsItems.map { $0.itemID }
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}
