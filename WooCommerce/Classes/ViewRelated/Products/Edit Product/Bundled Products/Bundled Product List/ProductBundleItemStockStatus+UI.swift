import Yosemite

extension ProductBundleItemStockStatus {
    /// Returns the localized text version of the Enum
    ///
    var description: String {
        switch self {
        case .inStock:
            return NSLocalizedString("In stock", comment: "Display label for the bundle item's inventory stock status")
        case .outOfStock:
            return NSLocalizedString("Out of stock", comment: "Display label for the bundle item's inventory stock status")
        case .onBackOrder:
            return NSLocalizedString("On back order", comment: "Display label for the bundle item's inventory stock status")
        }
    }
}
