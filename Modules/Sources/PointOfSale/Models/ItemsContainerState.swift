import Foundation

enum ItemsContainerState {
    case loading(isCatalogSyncing: Bool = false)
    case error(PointOfSaleErrorState)
    case content

    var isCatalogSyncing: Bool {
        switch self {
        case .loading(let isCatalogSyncing):
            return isCatalogSyncing
        default:
            return false
        }
    }
}

extension ItemsContainerState: Equatable {}
