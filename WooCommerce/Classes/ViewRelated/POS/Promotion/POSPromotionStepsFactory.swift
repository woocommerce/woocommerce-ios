import Foundation

/// Factory for creating the step descriptions shown in the POS Promotion modal.
///
struct POSPromotionStepsFactory {
    static func stepDescriptions() -> [String] {
        [
            Localization.step1Description,
            Localization.step2Description,
            Localization.step3Description,
            Localization.step4Description,
            Localization.step5Description
        ]
    }
}

// MARK: - Localization

private enum Localization {
    static let step1Description = NSLocalizedString(
        "posPromotion.step1.description",
        value: "Take payments in person and connect everything back to your store — all through the WooCommerce mobile app.",
        comment: "Description for the first step of the POS promotion modal"
    )

    static let step2Description = NSLocalizedString(
        "posPromotion.step2.description",
        value: "Real-time syncing for inventory, customer, and order data between your online store and POS.",
        comment: "Description for the second step of the POS promotion modal"
    )

    static let step3Description = NSLocalizedString(
        "posPromotion.step3.description",
        value: "Quick and simple to learn.",
        comment: "Description for the third step of the POS promotion modal"
    )

    static let step4Description = NSLocalizedString(
        "posPromotion.step4.description",
        value: "Built right into the WooCommerce mobile app — no third-party integration required.",
        comment: "Description for the fourth step of the POS promotion modal"
    )

    static let step5Description = NSLocalizedString(
        "posPromotion.step5.description",
        value: "Use with WooPayments or Stripe payment gateways.",
        comment: "Description for the fifth step of the POS promotion modal"
    )
}
