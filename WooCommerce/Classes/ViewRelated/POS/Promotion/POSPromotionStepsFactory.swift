import Foundation

/// Factory for creating the steps shown in the POS Promotion modal.
///
struct POSPromotionStepsFactory {
    static func steps() -> [POSPromotionStepViewModel] {
        [
            .init(title: Localization.Step1.title,
                  description: Localization.Step1.description),
            .init(title: Localization.Step2.title,
                  description: Localization.Step2.description),
            .init(title: Localization.Step3.title,
                  description: Localization.Step3.description),
            .init(title: Localization.Step4.title,
                  description: Localization.Step4.description),
            .init(title: Localization.Step5.title,
                  description: Localization.Step5.description)
        ]
    }
}

// MARK: - Localization

private enum Localization {
    enum Step1 {
        static let title = NSLocalizedString(
            "posPromotion.step1.title",
            value: "Run POS with the WooCommerce mobile app",
            comment: "Title for the first step of the POS promotion modal"
        )

        static let description = NSLocalizedString(
            "posPromotion.step1.description",
            value: "Take payments in person and connect everything back to your store — all through the WooCommerce mobile app.",
            comment: "Description for the first step of the POS promotion modal"
        )
    }

    enum Step2 {
        static let title = NSLocalizedString(
            "posPromotion.step2.title",
            value: "Run POS with the WooCommerce mobile app",
            comment: "Title for the second step of the POS promotion modal"
        )

        static let description = NSLocalizedString(
            "posPromotion.step2.description",
            value: "Real-time syncing for inventory, customer, and order data between your online store and POS.",
            comment: "Description for the second step of the POS promotion modal"
        )
    }

    enum Step3 {
        static let title = NSLocalizedString(
            "posPromotion.step3.title",
            value: "Run POS with the WooCommerce mobile app",
            comment: "Title for the third step of the POS promotion modal"
        )

        static let description = NSLocalizedString(
            "posPromotion.step3.description",
            value: "Quick and simple to learn.",
            comment: "Description for the third step of the POS promotion modal"
        )
    }

    enum Step4 {
        static let title = NSLocalizedString(
            "posPromotion.step4.title",
            value: "Run POS with the WooCommerce mobile app",
            comment: "Title for the fourth step of the POS promotion modal"
        )

        static let description = NSLocalizedString(
            "posPromotion.step4.description",
            value: "Built right into the WooCommerce mobile app — no third-party integration required.",
            comment: "Description for the fourth step of the POS promotion modal"
        )
    }

    enum Step5 {
        static let title = NSLocalizedString(
            "posPromotion.step5.title",
            value: "Run POS with the WooCommerce mobile app",
            comment: "Title for the fifth step of the POS promotion modal"
        )

        static let description = NSLocalizedString(
            "posPromotion.step5.description",
            value: "Use with WooPayments or Stripe payment gateways.",
            comment: "Description for the fifth step of the POS promotion modal"
        )
    }
}
