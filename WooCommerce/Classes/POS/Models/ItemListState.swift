import protocol Yosemite.POSDisplayableItem
import protocol Yosemite.POSOrderableItem

enum ItemListState: Equatable {
    case empty
    case initialLoading
    case loading(_ currentItems: [any POSDisplayableItem])
    case loaded(_ items: [any POSDisplayableItem])
    case error(PointOfSaleErrorState)

    var isLoadingAfterInitialLoad: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }

    static func == (lhs: ItemListState, rhs: ItemListState) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty),
            (.initialLoading, .initialLoading):
            return true
        case (.loading(let lhsItems), .loading(let rhsItems)),
            (.loaded(let lhsItems), .loaded(let rhsItems)):
            return lhsItems.isEqual(to: rhsItems)
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}
