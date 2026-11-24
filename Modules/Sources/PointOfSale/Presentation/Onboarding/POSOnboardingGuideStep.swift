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

    static let saleSteps = [Localization.saleStepAddProducts, Localization.saleStepCheckOut, Localization.saleStepGetPaid]
}

private extension POSOnboardingGuideStep {
    enum Localization {
        static let checkoutTitle = NSLocalizedString(
            "pos.onboardingGuide.checkout.title.v2",
            value: "Built for selling in person",
            comment: "Title of the first step of the POS onboarding guide shown on iPhone."
        )
        static let checkoutMessage = NSLocalizedString(
            "pos.onboardingGuide.checkout.message.v3",
            value: "Take payments with Tap to Pay on iPhone, a card reader or cash.",
            comment: "Message of the first step of the POS onboarding guide shown on iPhone."
        )
        static let oneStoreTitle = NSLocalizedString(
            "pos.onboardingGuide.oneStore.title.v3",
            value: "One store for every sale",
            comment: "Title of the second step of the POS onboarding guide shown on iPhone."
        )
        static let oneStoreMessage = NSLocalizedString(
            "pos.onboardingGuide.oneStore.message.v3",
            value: "POS uses your store's products, prices and stock, and records every sale there. Nothing to reconcile.",
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
        static let saleStepGetPaid = NSLocalizedString(
            "pos.onboardingGuide.howASaleWorks.getPaid",
            value: "Get paid",
            comment: "Third of three short labels for the steps of a sale in the POS onboarding guide: the customer pays."
        )
    }
}
