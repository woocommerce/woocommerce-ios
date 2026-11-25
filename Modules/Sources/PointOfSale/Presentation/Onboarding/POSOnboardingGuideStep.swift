import Foundation

enum POSOnboardingGuideStep: Int, CaseIterable, Identifiable {
    case checkout
    case oneStore
    case howASaleWorks

    var id: Int { rawValue }

    var illustration: PointOfSaleAssets {
        switch self {
        case .checkout:
            .store
        case .oneStore:
            .tshirtsSync
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

    var message: String {
        switch self {
        case .checkout:
            Localization.checkoutMessage
        case .oneStore:
            Localization.oneStoreMessage
        case .howASaleWorks:
            Localization.howASaleWorksMessage
        }
    }
}

private extension POSOnboardingGuideStep {
    enum Localization {
        static let checkoutTitle = NSLocalizedString(
            "pos.onboardingGuide.checkout.title.v3",
            value: "Sell in person with Point of Sale",
            comment: "Title of the first step of the POS onboarding guide shown on iPhone."
        )
        static let checkoutMessage = NSLocalizedString(
            "pos.onboardingGuide.checkout.message.v4",
            value: "Take payments with Tap to Pay on iPhone, a card reader, or cash.",
            comment: "Message of the first step of the POS onboarding guide shown on iPhone."
        )
        static let oneStoreTitle = NSLocalizedString(
            "pos.onboardingGuide.oneStore.title.v4",
            value: "Same store, more ways to sell",
            comment: "Title of the second step of the POS onboarding guide shown on iPhone."
        )
        static let oneStoreMessage = NSLocalizedString(
            "pos.onboardingGuide.oneStore.message.v6",
            value: "A single source of truth for products, prices, stock, and orders across online and in‑person sales.",
            comment: "Message of the second step of the POS onboarding guide shown on iPhone. " +
                "\"in‑person\" uses a non-breaking hyphen so it doesn't split across lines."
        )
        static let howASaleWorksTitle = NSLocalizedString(
            "pos.onboardingGuide.howASaleWorks.title.v2",
            value: "Selling in person is simple",
            comment: "Title of the third step of the POS onboarding guide shown on iPhone."
        )
        static let howASaleWorksMessage = NSLocalizedString(
            "pos.onboardingGuide.howASaleWorks.message",
            value: "Add items to the cart, tap Check out, and choose a payment method.",
            comment: "Message of the third step of the POS onboarding guide shown on iPhone. " +
                "Check out is the name of the button that starts the payment."
        )
    }
}
