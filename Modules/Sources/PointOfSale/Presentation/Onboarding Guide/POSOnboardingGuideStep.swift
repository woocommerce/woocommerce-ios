import Foundation

enum POSOnboardingGuideStep: Int, CaseIterable, Identifiable {
    case checkout
    case oneStore
    case howASaleWorks

    var id: Int { rawValue }

    var heroSystemImage: String {
        switch self {
        case .checkout:
            "cart.circle.fill"
        case .oneStore:
            "storefront.circle.fill"
        case .howASaleWorks:
            // Same symbol as `POSTapToPayHeroView`, which the merchant sees at checkout.
            "wave.3.right.circle.fill"
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

    /// Step 3 shows `saleSteps` as a numbered list instead.
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

    var saleSteps: [String] {
        switch self {
        case .checkout, .oneStore:
            []
        case .howASaleWorks:
            [Localization.saleStepAddProducts, Localization.saleStepCheckOut, Localization.saleStepPresentCard, Localization.saleStepDone]
        }
    }
}

private extension POSOnboardingGuideStep {
    enum Localization {
        static let checkoutTitle = NSLocalizedString(
            "pos.onboardingGuide.checkout.title",
            value: "A checkout made for selling in person",
            comment: "Title of the first step of the POS onboarding guide shown on iPhone."
        )
        static let checkoutMessage = NSLocalizedString(
            "pos.onboardingGuide.checkout.message",
            value: "Add products, take payment with Tap to Pay or cash, and you're done in seconds.",
            comment: "Message of the first step of the POS onboarding guide shown on iPhone."
        )
        static let oneStoreTitle = NSLocalizedString(
            "pos.onboardingGuide.oneStore.title",
            value: "One store, online and in person",
            comment: "Title of the second step of the POS onboarding guide shown on iPhone."
        )
        static let oneStoreMessage = NSLocalizedString(
            "pos.onboardingGuide.oneStore.message",
            value: "POS uses the products, prices and stock from your WooCommerce store. " +
                "Every sale is recorded straight in your store, so there's no separate system to keep up to date.",
            comment: "Message of the second step of the POS onboarding guide shown on iPhone."
        )
        static let howASaleWorksTitle = NSLocalizedString(
            "pos.onboardingGuide.howASaleWorks.title",
            value: "How a sale works",
            comment: "Title of the third step of the POS onboarding guide shown on iPhone, above a numbered list of the steps of a sale."
        )
        static let saleStepAddProducts = NSLocalizedString(
            "pos.onboardingGuide.howASaleWorks.addProducts",
            value: "Add products",
            comment: "First item of the numbered list of the steps of a sale in the POS onboarding guide."
        )
        static let saleStepCheckOut = NSLocalizedString(
            "pos.onboardingGuide.howASaleWorks.checkOut",
            value: "Check out",
            comment: "Second item of the numbered list of the steps of a sale in the POS onboarding guide."
        )
        static let saleStepPresentCard = NSLocalizedString(
            "pos.onboardingGuide.howASaleWorks.presentCard",
            value: "Your customer holds their card or phone near the top of your iPhone",
            comment: "Third item of the numbered list of the steps of a sale in the POS onboarding guide, describing a Tap to Pay payment."
        )
        static let saleStepDone = NSLocalizedString(
            "pos.onboardingGuide.howASaleWorks.done",
            value: "Done",
            comment: "Last item of the numbered list of the steps of a sale in the POS onboarding guide: the sale is complete."
        )
    }
}
