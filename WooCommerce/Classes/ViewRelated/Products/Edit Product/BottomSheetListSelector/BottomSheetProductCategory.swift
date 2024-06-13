import Foundation

/// Product creation option's category.
/// Used to group the options on the product creation sheet.
///
enum BottomSheetProductCategory: CaseIterable {
    case standard
    case subscription
    case other

    /// Categorization for each available product types.
    /// Depending on store configurations, some types will need to be excluded before being used in the UI.
    var productTypes: [BottomSheetProductType] {
        switch self {
        case .standard:
            return [.simple(isVirtual: false), .simple(isVirtual: true), .variable, .blank]
        case .subscription:
            return [.subscription, .variableSubscription]
        case .other:
            return [.custom("custom"), .grouped, .affiliate]
        }
    }

    var label: String {
        switch self {
        case .standard:
            return NSLocalizedString(
                "productCreationCategory.standard",
                value: "Standard",
                comment: "Category label for standard product creation types"
            )
        case .subscription:
            return NSLocalizedString(
                "productCreationCategory.subscription",
                value: "Subscription",
                comment: "Category label for subscription product creation types"
            )
        case .other:
            return NSLocalizedString(
                "productCreationCategory.other",
                value: "Other",
                comment: "Category label for other product creation types"
            )
        }
    }
}
