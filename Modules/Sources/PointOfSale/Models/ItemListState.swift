import enum Yosemite.POSItem

enum ItemListState {
    case initial
    case loading(_ currentItems: [POSItem])
    case loaded(_ items: [POSItem], hasMoreItems: Bool)
    case inlineError(_ items: [POSItem], error: PointOfSaleErrorState, context: InlineErrorContext)
    case error(PointOfSaleErrorState)
    case empty

    enum InlineErrorContext {
        case refresh
        case pagination
    }

    var isLoaded: Bool {
        switch self {
        case .loaded:
            return true
        default:
            return false
        }
    }

    var isEmpty: Bool {
        switch self {
        case .empty:
            return true
        default:
            return false
        }
    }
}

extension ItemListState {
    var items: [POSItem] {
        switch self {
        case .loading(let items),
                .loaded(let items, _),
                .inlineError(let items, _, _):
            return items
        case .initial, .error, .empty:
            return []
        }
    }
}

extension ItemListState: Equatable {}
