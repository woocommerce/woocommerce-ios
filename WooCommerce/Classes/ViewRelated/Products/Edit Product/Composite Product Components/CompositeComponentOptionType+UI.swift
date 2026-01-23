import Foundation
import Yosemite

extension CompositeComponentOptionType {
    /// Returns the localized text version of the Enum
    ///
    var description: String {
        switch self {
        case .productIDs:
            return NSLocalizedString("Products", comment: "Display label for the composite product's component option type")
        case .categoryIDs:
            return NSLocalizedString("Categories", comment: "This text appears as a title/label for the Categories section in the product editing interface, allowing merchants to assign product categories. It's used in bottom sheet actions, composite product component options, and as a row title in the main product form.")
        }
    }
}
