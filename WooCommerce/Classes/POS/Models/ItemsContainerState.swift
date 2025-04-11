import Foundation

enum ItemsContainerState {
    case loading
    case error(PointOfSaleErrorState)
    case content
}

extension ItemsContainerState: Equatable {}
