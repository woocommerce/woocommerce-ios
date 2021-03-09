import Foundation


/// Represents a ProductStockStatus Entity.
///
public enum ProductStockStatus: Codable, Hashable, GeneratedFakeable {
    case inStock
    case outOfStock
    case onBackOrder
    case custom(String) // in case there are extensions modifying product stock statuses
}


/// RawRepresentable Conformance
///
extension ProductStockStatus: RawRepresentable {

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.inStock:
            self = .inStock
        case Keys.outOfStock:
            self = .outOfStock
        case Keys.onBackOrder:
            self = .onBackOrder
        default:
            self = .custom(rawValue)
        }
    }

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
        case .inStock:              return Keys.inStock
        case .outOfStock:           return Keys.outOfStock
        case .onBackOrder:          return Keys.onBackOrder
        case .custom(let payload):  return payload
        }
    }

    /// Returns the localized text version of the Enum
    ///
    public var description: String {
        switch self {
        case .inStock:
            return NSLocalizedString("In stock", comment: "Display label for the product's inventory stock status")
        case .outOfStock:
            return NSLocalizedString("Out of stock", comment: "Display label for the product's inventory stock status")
        case .onBackOrder:
            return NSLocalizedString("On back order", comment: "Display label for the product's inventory stock status")
        case .custom(let payload):
            return payload // unable to localize at runtime.
        }
    }
}


/// Enum containing the 'Known' Product Stock Status Keys
///
private enum Keys {
    static let inStock     = "instock"
    static let outOfStock  = "outofstock"
    static let onBackOrder = "onbackorder"
}
