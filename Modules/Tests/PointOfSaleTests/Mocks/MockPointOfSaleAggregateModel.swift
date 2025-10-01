import Foundation
@testable import PointOfSale
import enum Yosemite.POSItem
import protocol Yosemite.POSOrderableItem
import enum Yosemite.POSItemType

final class MockPointOfSaleAggregateModel: PointOfSaleAggregateModelProtocol {
    var cart: Cart = .init()

    func addToCart(_ item: POSItem) { }

    func saveSearchTerm(_ term: String, for itemType: POSItemType) { }
}
