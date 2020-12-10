import Foundation

extension ProductStockStatus {
    public static func from(quantity: Int64) -> ProductStockStatus {
        switch quantity {
            case Int64.min ..< 0:
                return .onBackOrder
            case 0:
                return .outOfStock
            case 1...Int64.max:
                return .inStock
            default:
                preconditionFailure("Unable to parse quantity")
        }
    }
}
