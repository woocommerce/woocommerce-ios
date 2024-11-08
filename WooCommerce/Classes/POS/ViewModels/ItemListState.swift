import protocol Yosemite.POSItem

enum ItemListState: Equatable {
    case empty
    case initialLoading
    case loading(_ currentItems: [POSItem])
    case loaded(_ items: [POSItem])
    case error(ItemListErrorModel)

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
        case .initialLoading, .loading:
            return true
        default:
            return false
        }
    }

    var isLoadingNextPage: Bool {
        switch self {
        case .loading(let currentItems):
            return currentItems.isNotEmpty
        default:
            return false
        }
    }

    var hasError: ItemListErrorModel {
        switch self {
        case .error(let errorModel):
            return errorModel
        default:
            return ItemListErrorModel(title: "Unknown error",
                                      subtitle: "Unknown error",
                                      buttonText: "Retry")
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
