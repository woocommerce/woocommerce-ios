import protocol Yosemite.POSItem

enum PointOfSaleItemListState: Equatable {
    case empty
    case initialLoading
    case loading
    case loaded([POSItem])
    case error(PointOfSaleErrorState)

    var isLoaded: Bool {
        switch self {
        case .loaded:
            return true
        default:
            return false
        }
    }

    var isLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }

    var hasError: PointOfSaleErrorState {
        switch self {
        case .error(let errorModel):
            return errorModel
        default:
            return PointOfSaleErrorState(title: "Unknown error",
                                         subtitle: "Unknown error",
                                         buttonText: "Retry")
        }
    }

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
