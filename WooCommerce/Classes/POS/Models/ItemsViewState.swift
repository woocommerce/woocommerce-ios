import enum Yosemite.POSItem
import struct Yosemite.POSParentProduct

struct ItemsViewState: Equatable {
    let containerState: ContainerState
    let itemsStackState: ItemsStackState
}

enum ContainerState: Equatable {
    case empty
    case initialLoading
    case content
    case error(PointOfSaleErrorState)
}

extension ContainerState: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .empty:
            hasher.combine(0)
        case .initialLoading:
            hasher.combine(1)
        case .content:
            hasher.combine(2)
        case .error(let error):
            hasher.combine(error)
        }
    }
}

struct ItemsStackState: Equatable {
    var rootState: ItemListState
    var itemStates: [POSItem: ItemListState]
}

enum ItemListState: Equatable {
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

extension ItemListState: Hashable {
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

