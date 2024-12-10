import enum Yosemite.POSItem
import struct Yosemite.POSParentProduct

enum ItemListState: Equatable {
    case empty
    case initialLoading
    case loading(_ currentItems: [POSItem], context: NavigationContext, pageInfo: PageInfo)
    case loaded(_ items: [POSItem], context: NavigationContext, pageInfo: PageInfo)
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

struct PageInfo: Equatable {
    let currentPage: Int
    let hasMorePages: Bool
}

enum NavigationContext: Equatable {
    case root
    case child(parent: POSParentProduct, parentItem: POSItem)
}
