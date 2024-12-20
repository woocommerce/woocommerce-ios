import enum Yosemite.POSItem
import Codegen

enum ItemListState {
    case loading(_ currentItems: [POSItem])
    case loaded(_ items: [POSItem])
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

extension ItemListState: Equatable, GeneratedCopiable {}
