/// Creatable product types for standard (non-CIAB) sites.
///
/// Includes all product types with subscription eligibility as an orthogonal signal.
///
struct StandardCreatableProductTypeProvider: CreatableProductTypeProviding {
    private let isEligibleForSubscriptions: Bool

    init(subscriptionEligibility: WooSubscriptionProductsEligibilityCheckerProtocol) {
        self.isEligibleForSubscriptions = subscriptionEligibility.isSiteEligible()
    }

    var creatableProductTypes: [BottomSheetProductType] {
        [
            .simple(isVirtual: false),
            .simple(isVirtual: true),
            isEligibleForSubscriptions ? .subscription : nil,
            .variable,
            isEligibleForSubscriptions ? .variableSubscription : nil,
            .grouped,
            .affiliate
        ].compactMap { $0 }
    }
}

/// Creatable product types for CIAB sites.
///
/// Only simple and affiliate products are available for creation.
///
struct CIABCreatableProductTypeProvider: CreatableProductTypeProviding {
    var creatableProductTypes: [BottomSheetProductType] {
        [
            .simple(isVirtual: false),
            .simple(isVirtual: true),
            .affiliate
        ]
    }
}
