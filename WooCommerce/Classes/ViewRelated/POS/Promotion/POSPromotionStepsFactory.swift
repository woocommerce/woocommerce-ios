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
        comment: "This text appears as a descriptive step in a POS (Point of Sale) promotion modal that introduces users to the benefits of using WooCommerce's in-person payment features. It's the first step description in a multi-step promotional flow explaining how the mobile app can handle physical store transactions."
    )

    static let step2Description = NSLocalizedString(
        "posPromotion.step2.description",
        value: "Real-time syncing for inventory, customer, and order data between your online store and POS.",
        comment: "This text appears as a descriptive label in step 2 of a POS (Point of Sale) promotion modal that introduces users to the benefits of the WooCommerce POS feature. It explains the real-time data synchronization capability between online store and physical point-of-sale systems."
    )

    static let step3Description = NSLocalizedString(
        "posPromotion.step3.description",
        value: "Quick and simple to learn.",
        comment: "This text appears as a description for the third step in a POS (Point of Sale) promotional modal that introduces users to the WooCommerce POS feature. It highlights the ease of use as one of the key selling points in a multi-step promotional flow within the mobile app."
    )

    static let step4Description = NSLocalizedString(
        "posPromotion.step4.description",
        value: "Built right into the WooCommerce mobile app — no third-party integration required.",
        comment: "This text appears as a descriptive label for the fourth step in a POS (Point of Sale) promotion modal that explains the benefits of the WooCommerce POS feature to users. It emphasizes that the POS functionality is integrated directly into the app without requiring external tools."
    )

    static let step5Description = NSLocalizedString(
        "posPromotion.step5.description",
        value: "Use with WooPayments or Stripe payment gateways.",
        comment: "This text appears as a description for the fifth step in a Point of Sale (POS) promotion modal that introduces users to the WooCommerce POS feature. It specifically explains the payment gateway compatibility requirements for using the POS system."
    )
}
