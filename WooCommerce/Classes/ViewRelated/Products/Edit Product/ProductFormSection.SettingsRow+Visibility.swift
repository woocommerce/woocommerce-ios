import Foundation
import Yosemite

extension ProductFormSection.SettingsRow {
    func isVisible(product: Product) -> Bool {
        guard let bottomSheetAction = bottomSheetAction else {
            // If there is no corresponding bottom sheet action, the settings row is visible by default.
            return true
        }
        return bottomSheetAction.isVisible(product: product) == false
    }

    private var bottomSheetAction: ProductFormBottomSheetAction? {
        switch self {
        case .inventory:
            return .editInventorySettings
        case .shipping:
            return .editShippingSettings
        case .categories:
            return .editCategories
        case .briefDescription:
            return .editBriefDescription
        default:
            return nil
        }
    }
}
