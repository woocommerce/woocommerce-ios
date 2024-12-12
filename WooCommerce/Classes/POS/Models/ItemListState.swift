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

extension ItemListState: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .empty:
            hasher.combine(0)
        case .initialLoading:
            hasher.combine(1)
        case .loading(let items, let context, let pageInfo),
                .loaded(let items, let context, let pageInfo):
            hasher.combine(items)
            hasher.combine(context)
            hasher.combine(pageInfo)
        case .error(let error):
            hasher.combine(error)
        }
    }
}

enum ItemListViewState: Equatable {
    case loading(_ currentItems: [POSItem], context: NavigationContext, pageInfo: PageInfo)
    case loaded(_ items: [POSItem], context: NavigationContext, pageInfo: PageInfo)

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
        case .loading(let items, let context, let pageInfo),
                .loaded(let items, let context, let pageInfo):
            hasher.combine(items)
            hasher.combine(context)
            hasher.combine(pageInfo)
        }
    }
}

struct PageInfo: Equatable, Hashable {
    let currentPage: Int
    let hasMorePages: Bool
}

enum NavigationContext: Equatable {
    case root
    case child(parent: POSParentProduct, parentItem: POSItem)
}

extension NavigationContext: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .root:
            hasher.combine(0)
        case .child(parent: let parent, parentItem: let parentItem):
            hasher.combine(parent)
            hasher.combine(parentItem)
        }
    }
}
