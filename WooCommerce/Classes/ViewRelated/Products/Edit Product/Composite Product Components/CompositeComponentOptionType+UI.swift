import Yosemite

extension CompositeComponentOptionType {
    /// Returns the localized text version of the Enum
    ///
    var description: String {
        switch self {
        case .productIDs:
            return NSLocalizedString("Products", comment: "Display label for the composite product's component option type")
        case .categoryIDs:
            return NSLocalizedString("Categories", comment: "Display label for the composite product's component option type")
        }
    }
}