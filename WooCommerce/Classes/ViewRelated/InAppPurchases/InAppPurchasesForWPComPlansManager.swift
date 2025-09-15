import Foundation
import Yosemite

protocol WPComPlanProduct {
    // The localized product name, to be used as title in UI
    var displayName: String { get }
    // The localized product description
    var description: String { get }
    // The unique product identifier. To be used in further actions e.g purchasing a product
    var id: String { get }
    // The localized price, including currency
    var displayPrice: String { get }
}
