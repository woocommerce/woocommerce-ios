import Foundation

extension StoreCreationCategoryQuestionViewModel {
    /// Industry options for a WooCommerce store. The raw value is the value that is sent to the submission API.
    /// The sources of truth are at:
    /// - WC industry options: `https://github.com/woocommerce/woocommerce/blob/trunk/plugins/woocommerce-admin/client/core-profiler/pages/BusinessInfo.tsx#L32`
    enum Category: String, Equatable {
        case clothingAccessories = "clothing_and_accessories"
        case healthBeauty = "health_and_beauty"
        case electronicsComputers = "electronics_and_computers"
        case foodDrink = "food_and_drink"
        case homeFurnitureGarden = "home_furniture_and_garden"
        case educationAndLearning = "education_and_learning"
        case other = "other"
    }

    var categories: [Category] {
        [
            .clothingAccessories,
            .healthBeauty,
            .foodDrink,
            .homeFurnitureGarden,
            .educationAndLearning,
            .electronicsComputers,
            .other
        ]
    }
}

extension StoreCreationCategoryQuestionViewModel.Category {
    var name: String {
        switch self {
        case .clothingAccessories:
            return NSLocalizedString("Clothing and accessories", comment: "Industry option in the store creation category question.")
        case .healthBeauty:
            return NSLocalizedString("Health and beauty", comment: "Industry option in the store creation category question.")
        case .electronicsComputers:
            return NSLocalizedString("Electronics and computers", comment: "Industry option in the store creation category question.")
        case .foodDrink:
            return NSLocalizedString("Food and drink", comment: "Industry option in the store creation category question.")
        case .homeFurnitureGarden:
            return NSLocalizedString("Home, furniture, and garden", comment: "Industry option in the store creation category question.")
        case .educationAndLearning:
            return NSLocalizedString("Education and learning", comment: "Industry option in the store creation category question.")
        case .other:
            return NSLocalizedString("Other", comment: "Industry option in the store creation category question.")
        }
    }
}
