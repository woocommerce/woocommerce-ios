import Foundation

enum ItemsContainerState {
    case loading
    case empty
    case error(PointOfSaleErrorState)
    case content
}

extension ItemsContainerState: Equatable {}
