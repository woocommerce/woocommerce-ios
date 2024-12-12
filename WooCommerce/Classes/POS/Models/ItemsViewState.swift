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

struct ItemListState: Equatable, Hashable {
    var loadState: LoadState
    var items: [POSItem]
    var pageInfo: PageInfo

    var isLoading: Bool {
        switch loadState {
        case .loading:
            return true
        default:
            return false
        }
    }

    enum LoadState: Equatable, Hashable {
        case loading
        case loaded
    }
}

//extension ItemListState: Hashable {
//    public func hash(into hasher: inout Hasher) {
//        switch self {
//        case .loading(let items, let pageInfo),
//                .loaded(let items, let pageInfo):
//            hasher.combine(items)
//            hasher.combine(pageInfo)
//        }
//    }
//}

struct PageInfo: Equatable, Hashable {
    let currentPage: Int
    let hasMorePages: Bool
}

