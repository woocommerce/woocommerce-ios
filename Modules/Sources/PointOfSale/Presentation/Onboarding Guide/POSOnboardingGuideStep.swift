import Foundation

enum POSOnboardingGuideStep: Int, CaseIterable, Identifiable {
    case checkout
    case oneStore
    case howASaleWorks

    var id: Int { rawValue }

    var illustration: PointOfSaleAssets {
        switch self {
        case .checkout:
            .onboardingStorefront
        case .oneStore:
            .onboardingSync
        case .howASaleWorks:
            .readyForPayment
        }
    }

    var title: String {
        switch self {
        case .checkout:
            Localization.checkoutTitle
        case .oneStore:
            Localization.oneStoreTitle
        case .howASaleWorks:
            Localization.howASaleWorksTitle
        }
    }

    /// The last step shows `saleSteps` instead.
    var message: String? {
        switch self {
        case .checkout:
            Localization.checkoutMessage
        case .oneStore:
            Localization.oneStoreMessage
        case .howASaleWorks:
            nil
        }
    }

    static let saleSteps = [Localization.saleStepAddProducts, Localization.saleStepCheckOut, Localization.saleStepTapCard]
}

private extension POSOnboardingGuideStep {
    enum Localization {
        static let checkoutTitle = NSLocalizedString(
            "pos.onboardingGuide.checkout.title.v2",
            value: "Built for selling in person",
            comment: "Title of the first step of the POS onboarding guide shown on iPhone."
        )
        static let checkoutMessage = NSLocalizedString(
            "pos.onboardingGuide.checkout.message.v2",
            value: "Add products, take payment with Tap to Pay or cash, and you're done.",
            comment: "Message of the first step of the POS onboarding guide shown on iPhone."
        )
        static let oneStoreTitle = NSLocalizedString(
            "pos.onboardingGuide.oneStore.title.v2",
            value: "Synced with your store",
            comment: "Title of the second step of the POS onboarding guide shown on iPhone."
        )
        static let oneStoreMessage = NSLocalizedString(
            "pos.onboardingGuide.oneStore.message.v2",
            value: "Products, prices and stock come from your store, and every sale is recorded there.",
            comment: "Message of the second step of the POS onboarding guide shown on iPhone."
        )
        static let howASaleWorksTitle = NSLocalizedString(
            "pos.onboardingGuide.howASaleWorks.title",
            value: "How a sale works",
            comment: "Title of the third step of the POS onboarding guide shown on iPhone."
        )
        static let saleStepAddProducts = NSLocalizedString(
            "pos.onboardingGuide.howASaleWorks.addProducts",
            value: "Add products",
            comment: "First of three short labels for the steps of a sale in the POS onboarding guide."
        )
        static let saleStepCheckOut = NSLocalizedString(
            "pos.onboardingGuide.howASaleWorks.checkOut",
            value: "Check out",
            comment: "Second of three short labels for the steps of a sale in the POS onboarding guide."
        )
        static let saleStepTapCard = NSLocalizedString(
            "pos.onboardingGuide.howASaleWorks.tapCard",
            value: "Tap card",
            comment: "Third of three short labels for the steps of a sale in the POS onboarding guide: " +
                "the customer taps their card or phone on the merchant's iPhone."
        )
    }
}
