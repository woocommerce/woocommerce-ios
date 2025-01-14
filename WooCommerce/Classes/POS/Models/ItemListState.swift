import enum Yosemite.POSItem
import Codegen

enum ItemListState {
    case loading(_ currentItems: [POSItem])
    case loaded(_ items: [POSItem], hasMoreItems: Bool)
    case inlineError(_ items: [POSItem], error: PointOfSaleErrorState)
    case error(PointOfSaleErrorState)

    var isLoading: Bool {
        switch self {
        case .loading:
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
                .inlineError(let items, _):
            return items
        case .error:
            return []
        }
    }
}

extension ItemListState: Equatable, GeneratedCopiable {}
