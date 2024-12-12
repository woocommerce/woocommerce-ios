import enum Yosemite.POSItem
import struct Yosemite.POSParentProduct

enum ItemListState: Equatable {
    case empty
    case initialLoading
    case itemsList
    case error(PointOfSaleErrorState)
}

extension ItemListState: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .empty:
            hasher.combine(0)
        case .initialLoading:
            hasher.combine(1)
        case .itemsList:
            hasher.combine(2)
        case .error(let error):
            hasher.combine(error)
        }
    }
}

enum ItemListViewState: Equatable {
    case loading(_ currentItems: [POSItem], pageInfo: PageInfo)
    case loaded(_ items: [POSItem], pageInfo: PageInfo)

    var isLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }
}

extension ItemListViewState: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .loading(let items, let pageInfo),
                .loaded(let items, let pageInfo):
            hasher.combine(items)
            hasher.combine(pageInfo)
        }
    }
}

struct PageInfo: Equatable, Hashable {
    let currentPage: Int
    let hasMorePages: Bool
}

