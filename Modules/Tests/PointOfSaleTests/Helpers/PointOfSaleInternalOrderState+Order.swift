import struct Yosemite.Order
@testable import PointOfSale

extension PointOfSaleInternalOrderState {
    var order: Order? {
        guard case .loaded(_, let order) = self else {
            return nil
        }
        return order
    }
}
