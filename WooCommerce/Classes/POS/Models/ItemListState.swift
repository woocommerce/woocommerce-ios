import enum Yosemite.POSItem

enum ItemListState {
    case loading(_ currentItems: [POSItem])
    case loaded(_ items: [POSItem], hasMoreItems: Bool)
    case inlineError(_ items: [POSItem], error: PointOfSaleErrorState, context: InlineErrorContext)
    case error(PointOfSaleErrorState)
    case empty

    enum InlineErrorContext {
        case refresh
        case pagination
    }

    var isLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }

    var isLoaded: Bool {
        switch self {
        case .loaded:
            return true
        default:
            return false
        }
    }

    var isInlineError: Bool {
        switch self {
        case .inlineError:
            return true
        default:
            return false
        }
    }

    var isError: Bool {
        switch self {
        case .error:
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
        case .error, .empty:
            return []
        }
    }
}

extension ItemListState: Equatable {}
