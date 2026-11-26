import Foundation

struct POSOnboardingGuideStep: Equatable {
    /// Stable step name sent with the guide's analytics events.
    let analyticsValue: String
    let illustration: PointOfSaleAssets
    let title: String
    let message: String

    static let all: [POSOnboardingGuideStep] = [
        .init(analyticsValue: "step_1",
              illustration: .store,
              title: Localization.sellInPersonTitle,
              message: Localization.sellInPersonMessage),
        .init(analyticsValue: "step_2",
              illustration: .tshirtsSync,
              title: Localization.sameStoreTitle,
              message: Localization.sameStoreMessage),
        .init(analyticsValue: "step_3",
              illustration: .readyForPayment,
              title: Localization.simpleSaleTitle,
              message: Localization.simpleSaleMessage)
    ]
}

private extension POSOnboardingGuideStep {
    enum Localization {
        static let sellInPersonTitle = NSLocalizedString(
            "pos.onboardingGuide.sellInPerson.title",
            value: "Sell in person with Point of Sale",
            comment: "Title of the first step of the POS onboarding guide shown on iPhone."
        )
        static let sellInPersonMessage = NSLocalizedString(
            "pos.onboardingGuide.sellInPerson.message",
            value: "Take payments with Tap to Pay on iPhone, a card reader, or cash.",
            comment: "Message of the first step of the POS onboarding guide shown on iPhone."
        )
        static let sameStoreTitle = NSLocalizedString(
            "pos.onboardingGuide.sameStore.title",
            value: "Same store, more ways to sell",
            comment: "Title of the second step of the POS onboarding guide shown on iPhone."
        )
        static let sameStoreMessage = NSLocalizedString(
            "pos.onboardingGuide.sameStore.message",
            value: "A single source of truth for products, prices, stock, and orders across online and in‑person sales.",
            comment: "Message of the second step of the POS onboarding guide shown on iPhone. " +
                "\"in‑person\" uses a non-breaking hyphen so it doesn't split across lines."
        )
        static let simpleSaleTitle = NSLocalizedString(
            "pos.onboardingGuide.simpleSale.title",
            value: "Selling in person is simple",
            comment: "Title of the third step of the POS onboarding guide shown on iPhone."
        )
        static let simpleSaleMessage = NSLocalizedString(
            "pos.onboardingGuide.simpleSale.message",
            value: "Add items to the cart, tap Check out, and choose a payment method.",
            comment: "Message of the third step of the POS onboarding guide shown on iPhone. " +
                "Check out is the name of the button that starts the payment."
        )
    }
}
