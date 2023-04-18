import Foundation

extension StoreCreationCategoryQuestionViewModel {
    /// Industry options for a WooCommerce store. The raw value is the value that is sent to the submission API.
    /// The sources of truth are at:
    /// - Stripe industries: https://support.stripe.com/questions/setting-an-industry-group-when-creating-a-stripe-account
    /// - WC industry options: `https://github.com/woocommerce/woocommerce/blob/
    ///   07a2f83f53352bc9c24f929b7dd787c95e91f4aa/plugins/woocommerce/src/Internal/Admin/Onboarding/OnboardingIndustries.php#L28-L69`
    enum Category: String, Equatable {
        case fashionApparelAccessories = "fashion-apparel-accessories"
        case healthBeauty = "health-beauty"
        case electronicsComputers = "electronics-computers"
        case foodDrink = "food-drink"
        case homeFurnitureGarden = "home-furniture-garden"
        case cbdOtherHempDerivedProducts = "cbd-other-hemp-derived-products"
        case educationAndLearning = "education-and-learning"
        case other = "other"
    }

    var categories: [Category] {
        [
            .fashionApparelAccessories,
            .healthBeauty,
            .electronicsComputers,
            .foodDrink,
            .homeFurnitureGarden,
            .cbdOtherHempDerivedProducts,
            .educationAndLearning,
            .other
        ]
    }
}

extension StoreCreationCategoryQuestionViewModel.Category {
    var name: String {
        switch self {
        case .fashionApparelAccessories:
            return NSLocalizedString("Fashion, apparel, and accessories", comment: "Industry option in the store creation category question.")
        case .healthBeauty:
            return NSLocalizedString("Health and beauty", comment: "Industry option in the store creation category question.")
        case .electronicsComputers:
            return NSLocalizedString("Electronics and computers", comment: "Industry option in the store creation category question.")
        case .foodDrink:
            return NSLocalizedString("Food and drink", comment: "Industry option in the store creation category question.")
        case .homeFurnitureGarden:
            return NSLocalizedString("Home, furniture, and garden", comment: "Industry option in the store creation category question.")
        case .cbdOtherHempDerivedProducts:
            return NSLocalizedString("CBD and other hemp-derived products", comment: "Industry option in the store creation category question.")
        case .educationAndLearning:
            return NSLocalizedString("Education and learning", comment: "Industry option in the store creation category question.")
        case .other:
            return NSLocalizedString("Other", comment: "Industry option in the store creation category question.")
        }
    }
}
