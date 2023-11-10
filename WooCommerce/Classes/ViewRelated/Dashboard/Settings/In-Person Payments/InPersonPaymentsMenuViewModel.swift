import Foundation
import SwiftUI
import Yosemite
import WooFoundation

class InPersonPaymentsMenuViewModel: ObservableObject {
    @Published private(set) var shouldShowTapToPaySection: Bool = true
    @Published private(set) var shouldShowCardReaderSection: Bool = true
    @Published private(set) var setUpTryOutTapToPayRowTitle: String = Localization.setUpTapToPayOnIPhoneRowTitle
    @Published private(set) var shouldShowTapToPayFeedbackRow: Bool = true
    @Published private(set) var shouldDisableManageCardReaders: Bool = false
    var shouldAlwaysHideSetUpButtonOnAboutTapToPay: Bool = false

    let siteID: Int64

    struct Dependencies {
        let cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration
        let onboardingUseCase: CardPresentPaymentsOnboardingUseCaseProtocol
        let cardReaderSupportDeterminer: CardReaderSupportDetermining
    }

    let dependencies: Dependencies

    init(siteID: Int64,
         dependencies: Dependencies) {
        self.siteID = siteID
        self.dependencies = dependencies
        updateOutputProperties()
    }

    func updateOutputProperties() {
        Task {
            await shouldAlwaysHideSetUpButtonOnAboutTapToPay = dependencies.cardReaderSupportDeterminer.hasPreviousTapToPayUsage()
        }
    }

    var setUpTapToPayViewModelsAndViews: SetUpTapToPayViewModelsOrderedList {
        SetUpTapToPayViewModelsOrderedList(
            siteID: siteID,
            configuration: dependencies.cardPresentPaymentsConfiguration,
            onboardingUseCase: dependencies.onboardingUseCase)
    }

    var aboutTapToPayViewModel: AboutTapToPayViewModel {
        AboutTapToPayViewModel(
            siteID: siteID,
            configuration: dependencies.cardPresentPaymentsConfiguration,
            cardPresentPaymentsOnboardingUseCase: dependencies.onboardingUseCase,
            shouldAlwaysHideSetUpTapToPayButton: shouldAlwaysHideSetUpButtonOnAboutTapToPay)
    }

    var manageCardReadersViewModelsAndViews: CardReaderSettingsViewModelsOrderedList {
        CardReaderSettingsViewModelsOrderedList(
            configuration: dependencies.cardPresentPaymentsConfiguration,
            siteID: siteID)
    }

    var purchaseCardReaderWebViewModel: PurchaseCardReaderWebViewViewModel {
        PurchaseCardReaderWebViewViewModel(
            configuration: dependencies.cardPresentPaymentsConfiguration,
            utmProvider: WooCommerceComUTMProvider(
                campaign: Constants.utmCampaign,
                source: Constants.utmSource,
                content: nil,
                siteID: siteID),
            onDismiss: {})

    }

}

private enum Constants {
    static let utmCampaign = "payments_menu_item"
    static let utmSource = "payments_menu"
}

private extension InPersonPaymentsMenuViewModel {
    enum Localization {
        static let setUpTapToPayOnIPhoneRowTitle = NSLocalizedString(
            "Set Up Tap to Pay on iPhone",
            comment: "Navigates to the Tap to Pay on iPhone set up flow. The full name is expected by Apple. " +
            "The destination screen also allows for a test payment, after set up.")

        static let tryOutTapToPayOnIPhoneRowTitle = NSLocalizedString(
            "Try Out Tap to Pay on iPhone",
            comment: "Navigates to the Tap to Pay on iPhone set up flow, after set up has been completed, when it " +
            "primarily allows for a test payment. The full name is expected by Apple.")
    }
}
