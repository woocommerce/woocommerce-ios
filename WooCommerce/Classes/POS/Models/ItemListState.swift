import enum Yosemite.POSItem
import protocol Yosemite.POSOrderableItem

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
}
