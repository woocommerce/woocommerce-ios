import enum Yosemite.POSItem

enum ItemListState: Equatable {
    case empty
    case initialLoading
    case loading(_ currentItems: [POSItem], parent: POSItem?, pageInfo: PageInfo)
    case loaded(_ items: [POSItem], parent: POSItem?, pageInfo: PageInfo)
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
