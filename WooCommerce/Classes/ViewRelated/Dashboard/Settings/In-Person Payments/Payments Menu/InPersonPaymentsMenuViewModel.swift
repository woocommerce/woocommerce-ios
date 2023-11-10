import Foundation
import SwiftUI
import Yosemite
import WooFoundation
import Combine

class InPersonPaymentsMenuViewModel: ObservableObject {
    @Published private(set) var shouldShowTapToPaySection: Bool = true
    @Published private(set) var shouldShowCardReaderSection: Bool = true
    @Published private(set) var shouldShowPaymentOptionsSection: Bool = false
    @Published private(set) var setUpTryOutTapToPayRowTitle: String = Localization.setUpTapToPayOnIPhoneRowTitle
    @Published private(set) var shouldShowTapToPayFeedbackRow: Bool = true
    @Published private(set) var shouldDisableManageCardReaders: Bool = true
    @Published var backgroundOnboardingInProgress: Bool = false
    @Published private(set) var cardPresentPaymentsOnboardingNotice: PermanentNotice?
    @Published var shouldShowOnboarding: Bool = false
    @Published private(set) var shouldShowManagePaymentGatewaysRow: Bool = false
    @Published private(set) var activePaymentGatewayName: String?
    @Published var presentCollectPayment: Bool = false
    @Published var presentSetUpTryOutTapToPay: Bool = false
    @Published var presentTapToPayFeedback: Bool = false

    var shouldAlwaysHideSetUpButtonOnAboutTapToPay: Bool = false

    private(set) var simplePaymentsNoticePublisher: AnyPublisher<SimplePaymentsNotice, Never>

    let siteID: Int64

    let payInPersonToggleViewModel = InPersonPaymentsCashOnDeliveryToggleRowViewModel()

    struct Dependencies {
        let cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration
        let onboardingUseCase: CardPresentPaymentsOnboardingUseCaseProtocol
        let cardReaderSupportDeterminer: CardReaderSupportDetermining
    }

    let dependencies: Dependencies

    private var cancellables: Set<AnyCancellable> = []

    init(siteID: Int64,
         dependencies: Dependencies) {
        self.siteID = siteID
        self.dependencies = dependencies
        self.simplePaymentsNoticePublisher = PassthroughSubject<SimplePaymentsNotice, Never>().eraseToAnyPublisher()
        observeOnboardingChanges()
        runCardPresentPaymentsOnboardingIfPossible()
        updateOutputProperties()
    }

    private func updateOutputProperties() {
        Task {
            let tapToPayWasPreviouslyUsed = await dependencies.cardReaderSupportDeterminer.hasPreviousTapToPayUsage()
            setUpTryOutTapToPayRowTitle = tapToPayWasPreviouslyUsed ? Localization.tryOutTapToPayOnIPhoneRowTitle : Localization.setUpTapToPayOnIPhoneRowTitle
            shouldAlwaysHideSetUpButtonOnAboutTapToPay = tapToPayWasPreviouslyUsed
        }
    }

    func onAppear() {
        runCardPresentPaymentsOnboardingIfPossible()
    }

    func collectPaymentTapped() {
        presentCollectPayment = true

        ServiceLocator.analytics.track(event: WooAnalyticsEvent.SimplePayments.simplePaymentsFlowStarted())
    }

    func setUpTryOutTapToPayTapped() {
        presentSetUpTryOutTapToPay = true
    }

    func tapToPayFeedbackTapped() {
        presentTapToPayFeedback = true
    }

    lazy var setUpTapToPayViewModelsAndViews: SetUpTapToPayViewModelsOrderedList = {
        SetUpTapToPayViewModelsOrderedList(
            siteID: siteID,
            configuration: dependencies.cardPresentPaymentsConfiguration,
            onboardingUseCase: dependencies.onboardingUseCase)
    }()

    lazy var aboutTapToPayViewModel: AboutTapToPayViewModel = {
        AboutTapToPayViewModel(
            siteID: siteID,
            configuration: dependencies.cardPresentPaymentsConfiguration,
            cardPresentPaymentsOnboardingUseCase: dependencies.onboardingUseCase,
            shouldAlwaysHideSetUpTapToPayButton: shouldAlwaysHideSetUpButtonOnAboutTapToPay)
    }()

    lazy var manageCardReadersViewModelsAndViews: CardReaderSettingsViewModelsOrderedList = {
        CardReaderSettingsViewModelsOrderedList(
            configuration: dependencies.cardPresentPaymentsConfiguration,
            siteID: siteID)
    }()

    lazy var purchaseCardReaderWebViewModel: PurchaseCardReaderWebViewViewModel = {
        PurchaseCardReaderWebViewViewModel(
            configuration: dependencies.cardPresentPaymentsConfiguration,
            utmProvider: WooCommerceComUTMProvider(
                campaign: Constants.utmCampaign,
                source: Constants.utmSource,
                content: nil,
                siteID: siteID),
            onDismiss: {})
    }()

    lazy var onboardingViewModel: InPersonPaymentsViewModel = {
        InPersonPaymentsViewModel(useCase: dependencies.onboardingUseCase)
    }()
}

// MARK: - Background onboarding
private extension InPersonPaymentsMenuViewModel {
    func observeOnboardingChanges() {
        guard dependencies.cardPresentPaymentsConfiguration.isSupportedCountry else {
            return
        }

        dependencies.onboardingUseCase.statePublisher
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: { [weak self] state in
                self?.refreshAfterNewOnboardingState(state)
        }).store(in: &cancellables)
    }

    func runCardPresentPaymentsOnboardingIfPossible() {
        guard dependencies.cardPresentPaymentsConfiguration.isSupportedCountry else {
            return
        }

        dependencies.onboardingUseCase.refreshIfNecessary()
    }

    func refreshAfterNewOnboardingState(_ state: CardPresentPaymentOnboardingState) {
        guard state != .loading else {
            backgroundOnboardingInProgress = true
            return
        }

        switch state {
        case let .completed(newPluginState):
            cardPresentPaymentsOnboardingNotice = nil
            shouldShowOnboarding = false
            updateManagePaymentGatewaysRowVisibility(shouldShow: newPluginState.available.count > 1)
            shouldDisableManageCardReaders = false
            activePaymentGatewayName = newPluginState.preferred.pluginName
        case .selectPlugin(true):
            // Selected plugin was cleared manually (e.g by tapping in this view on the plugin selection row)
            // No need to show the onboarding notice in this case.
            break
        default:
            cardPresentPaymentsOnboardingNotice = onboardingNotice
            break
        }
        updatePayInPersonToggleSelectedPlugin(from: state)

        backgroundOnboardingInProgress = false
    }

    func updateManagePaymentGatewaysRowVisibility(shouldShow: Bool) {
        shouldShowManagePaymentGatewaysRow = shouldShow
        shouldShowPaymentOptionsSection = shouldShow
    }

    func updatePayInPersonToggleSelectedPlugin(from state: CardPresentPaymentOnboardingState) {
        switch state {
        case let .completed(pluginState):
            payInPersonToggleViewModel.selectedPlugin = pluginState.preferred
        case let .codPaymentGatewayNotSetUp(plugin):
            payInPersonToggleViewModel.selectedPlugin = plugin
        default:
            payInPersonToggleViewModel.selectedPlugin = nil
        }
    }

    var onboardingNotice: PermanentNotice {
        PermanentNotice(
            message: Localization.inPersonPaymentsSetupNotFinishedNotice,
            callToActionTitle: Localization.inPersonPaymentsSetupNotFinishedNoticeButtonTitle,
            callToActionHandler: { [weak self] in
                ServiceLocator.analytics.track(.paymentsMenuOnboardingErrorTapped)
                self?.shouldShowOnboarding = true
            })
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

        static let inPersonPaymentsSetupNotFinishedNotice = NSLocalizedString(
            "menu.payments.inPersonPayments.setup.incomplete.notice.title",
            value: "In-Person Payments setup is incomplete.",
            comment: "Shows a notice pointing out that the user didn't finish the In-Person Payments setup, so some functionalities are disabled."
        )

        static let inPersonPaymentsSetupNotFinishedNoticeButtonTitle = NSLocalizedString(
            "menu.payments.inPersonPayments.setup.incomplete.notice.button.title",
            value: "Continue setup",
            comment: "Call to Action to finish the setup of In-Person Payments in the Menu"
        )
    }
}
