import Foundation

/// Actions in the product form bottom sheet to add more product details.
enum ProductFormBottomSheetAction {
    case editInventorySettings
    case editShippingSettings
    case editCategories
    case editBriefDescription
}

extension ProductFormBottomSheetAction {
    var title: String {
        switch self {
        case .editInventorySettings:
            return NSLocalizedString("Inventory",
                                     comment: "Title of the product form bottom sheet action for editing inventory settings.")
        case .editShippingSettings:
            return NSLocalizedString("Shipping",
                                     comment: "Title of the product form bottom sheet action for editing shipping settings.")
        case .editCategories:
            return NSLocalizedString("Categories",
                                     comment: "Title of the product form bottom sheet action for editing categories.")
        case .editBriefDescription:
            return NSLocalizedString("Short description",
                                     comment: "Title of the product form bottom sheet action for editing short description.")
        }
    }

    var subtitle: String {
        switch self {
        case .editInventorySettings:
            return NSLocalizedString("Update product inventory and SKU",
                                     comment: "Subtitle of the product form bottom sheet action for editing inventory settings.")
        case .editShippingSettings:
            return NSLocalizedString("Add weight and dimensions",
                                     comment: "Subtitle of the product form bottom sheet action for editing shipping settings.")
        case .editCategories:
            return NSLocalizedString("Organise your products into related groups",
                                     comment: "Subtitle of the product form bottom sheet action for editing categories.")
        case .editBriefDescription:
            return NSLocalizedString("A brief excerpt about your product",
                                     comment: "Subtitle of the product form bottom sheet action for editing short description.")
        }
    }
}
