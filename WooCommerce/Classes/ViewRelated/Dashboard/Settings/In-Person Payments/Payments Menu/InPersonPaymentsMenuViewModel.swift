import Experiments
import Foundation
import SwiftUI
import Yosemite
import WooFoundation
import Combine

@MainActor
final class InPersonPaymentsMenuViewModel: ObservableObject {
    @Binding var navigationPath: NavigationPath
    private var navigationPathBeforePaymentCollection: NavigationPath?

    @Published private(set) var shouldShowTapToPaySection: Bool = true
    @Published private(set) var shouldShowCardReaderSection: Bool = true
    @Published private(set) var shouldShowPaymentOptionsSection: Bool = false
    @Published private(set) var shouldShowDepositSummary: Bool = false
    @Published private(set) var setUpTryOutTapToPayRowTitle: String = Localization.setUpTapToPayOnIPhoneRowTitle
    @Published private(set) var shouldShowTapToPayFeedbackRow: Bool = true
    @Published private(set) var shouldBadgeTapToPayOnIPhone: Bool = false
    @Published private(set) var shouldDisableManageCardReaders: Bool = true
    @Published var backgroundOnboardingInProgress: Bool = false
    @Published private(set) var cardPresentPaymentsOnboardingNotice: PermanentNotice?
    @Published var shouldShowOnboarding: Bool = false
    @Published private(set) var shouldShowManagePaymentGatewaysRow: Bool = false
    @Published var presentManagePaymentGateways: Bool = false
    @Published private(set) var selectedPaymentGatewayName: String?
    @Published private(set) var selectedPaymentGatewayPlugin: CardPresentPaymentsPlugin?
    /// Whether the payment collection migration sheet is presented, bound to the migration sheet.
    @Published var presentCollectPaymentMigrationSheet: Bool = false
    /// Whether the migration sheet has been presented per payment collection session.
    @Published var hasPresentedCollectPaymentMigrationSheet: Bool = false
    /// Whether the custom amount flow should be presented after dismissing the payment collection migration sheet.
    @Published var presentCustomAmountAfterDismissingCollectPaymentMigrationSheet: Bool = false
    @Published var presentSetUpTryOutTapToPay: Bool = false
    @Published var presentAboutTapToPay: Bool = false
    @Published var presentTapToPayFeedback: Bool = false
    @Published var presentPurchaseCardReader: Bool = false
    @Published var presentManageCardReaders: Bool = false
    @Published var presentCardReaderManuals: Bool = false
    @Published var safariSheetURL: URL? = nil
    @Published var presentSupport: Bool = false
    @Published var depositViewModel: WooPaymentsDepositsOverviewViewModel? = nil
    @Published var isLoadingDepositSummary: Bool = false

    var shouldAlwaysHideSetUpButtonOnAboutTapToPay: Bool = false

    /// Set to a non-nil value when order form is shown.
    private(set) var orderViewModel: EditableOrderViewModel?

    let siteID: Int64

    var payInPersonToggleViewModel: InPersonPaymentsCashOnDeliveryToggleRowViewModelProtocol

    private(set) var paymentMethodsViewModel: PaymentMethodsViewModel?
    private var paymentMethodsNoticeSubscription: AnyCancellable?

    struct Dependencies {
        let cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration
        let onboardingUseCase: CardPresentPaymentsOnboardingUseCaseProtocol
        let cardReaderSupportDeterminer: CardReaderSupportDetermining
        let tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker
        let wooPaymentsDepositService: WooPaymentsDepositServiceProtocol?
        let analytics: Analytics
        let systemStatusService: SystemStatusServiceProtocol
        let noticePresenter: NoticePresenter
        let featureFlagService: FeatureFlagService

        init(cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration,
             onboardingUseCase: CardPresentPaymentsOnboardingUseCaseProtocol,
             cardReaderSupportDeterminer: CardReaderSupportDetermining,
             tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker = TapToPayBadgePromotionChecker(),
             wooPaymentsDepositService: WooPaymentsDepositServiceProtocol?,
             systemStatusService: SystemStatusServiceProtocol = SystemStatusService(stores: ServiceLocator.stores),
             analytics: Analytics = ServiceLocator.analytics,
             noticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
             featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
            self.cardPresentPaymentsConfiguration = cardPresentPaymentsConfiguration
            self.onboardingUseCase = onboardingUseCase
            self.cardReaderSupportDeterminer = cardReaderSupportDeterminer
            self.tapToPayBadgePromotionChecker = tapToPayBadgePromotionChecker
            self.wooPaymentsDepositService = wooPaymentsDepositService
            self.systemStatusService = systemStatusService
            self.analytics = analytics
            self.noticePresenter = noticePresenter
            self.featureFlagService = featureFlagService
        }
    }

    private let dependencies: Dependencies

    var cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration {
        dependencies.cardPresentPaymentsConfiguration
    }

    var onboardingUseCase: CardPresentPaymentsOnboardingUseCaseProtocol {
        dependencies.onboardingUseCase
    }

    private var analytics: Analytics {
        dependencies.analytics
    }

    private var cancellables: Set<AnyCancellable> = []

    init(siteID: Int64,
         dependencies: Dependencies,
         navigationPath: Binding<NavigationPath>,
         payInPersonToggleViewModel: InPersonPaymentsCashOnDeliveryToggleRowViewModelProtocol = InPersonPaymentsCashOnDeliveryToggleRowViewModel()) {
        self.siteID = siteID
        self.dependencies = dependencies
        self._navigationPath = navigationPath
        self.payInPersonToggleViewModel = payInPersonToggleViewModel
        observeOnboardingChanges()
        runCardPresentPaymentsOnboardingIfPossible()

        dependencies.tapToPayBadgePromotionChecker.$shouldShowTapToPayBadges
            .share()
            .assign(to: &$shouldBadgeTapToPayOnIPhone)

        Task { @MainActor in
            _ = try? await dependencies.systemStatusService.synchronizeSystemInformation(siteID: siteID)
            await updateOutputProperties()
            InPersonPaymentsMenuViewController().createUserActivity().becomeCurrent()
        }
    }

    /// Called when payment collection is shown to leave the payment collection flow.
    func dismissPaymentCollection() {
        while navigationPath != navigationPathBeforePaymentCollection {
            navigationPath.removeLast()
        }
    }

    private func updateOutputProperties() async {
        payInPersonToggleViewModel.refreshState()
        updateCardReadersSection()
        await updateTapToPaySection()
        await refreshDepositSummary()
    }

    private func refreshDepositSummary() async {
        guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.wooPaymentsDepositsOverviewInPaymentsMenu),
              let depositService = dependencies.wooPaymentsDepositService,
              await dependencies.systemStatusService.fetchSystemPluginWithPath(siteID: siteID,
                                                                               pluginPath: WooConstants.wooPaymentsPluginPath) != nil else {
            shouldShowDepositSummary = false
            return
        }

        shouldShowDepositSummary = true

        do {
            if depositViewModel == nil {
                isLoadingDepositSummary = true
            }
            let depositCurrencyViewModels = try await depositService.fetchDepositsOverview().map({
                WooPaymentsDepositsCurrencyOverviewViewModel(overview: $0)
            })
            isLoadingDepositSummary = false
            depositViewModel = WooPaymentsDepositsOverviewViewModel(currencyViewModels: depositCurrencyViewModels)
        } catch {
            shouldShowDepositSummary = false
            isLoadingDepositSummary = false
            analytics.track(event: .DepositSummary.depositSummaryError(error: error))
        }
    }

    func onAppear() async {
        runCardPresentPaymentsOnboardingIfPossible()
        await updateOutputProperties()
    }

    func collectPaymentTapped() {
        collectPayment()
        analytics.track(.paymentsMenuCollectPaymentTapped)
    }

    func setUpTryOutTapToPayTapped() {
        presentSetUpTryOutTapToPay = true
        analytics.track(.setUpTryOutTapToPayOnIPhoneTapped)
    }

    func aboutTapToPayTapped() {
        presentAboutTapToPay = true
        analytics.track(.aboutTapToPayOnIPhoneTapped)
    }

    func tapToPayFeedbackTapped() {
        presentTapToPayFeedback = true
    }

    func purchaseCardReaderTapped() {
        presentPurchaseCardReader = true
        analytics.track(.paymentsMenuOrderCardReaderTapped)
    }

    func manageCardReadersTapped() {
        presentManageCardReaders = true
        analytics.track(.paymentsMenuManageCardReadersTapped)
    }

    func cardReaderManualsTapped() {
        presentCardReaderManuals = true
        analytics.track(.paymentsMenuCardReadersManualsTapped)
    }

    func managePaymentGatewaysTapped() {
        presentManagePaymentGateways = true
        analytics.track(.paymentsMenuPaymentProviderTapped)
    }

    func preferredPluginSelected(plugin: CardPresentPaymentsPlugin) {
        dependencies.onboardingUseCase.clearPluginSelection()
        dependencies.onboardingUseCase.selectPlugin(plugin)
    }

    lazy var aboutTapToPayViewModel: AboutTapToPayViewModel = {
        AboutTapToPayViewModel(
            siteID: siteID,
            configuration: cardPresentPaymentsConfiguration,
            cardPresentPaymentsOnboardingUseCase: onboardingUseCase,
            shouldAlwaysHideSetUpTapToPayButton: shouldAlwaysHideSetUpButtonOnAboutTapToPay)
    }()

    lazy var purchaseCardReaderWebViewModel: PurchaseCardReaderWebViewViewModel = {
        PurchaseCardReaderWebViewViewModel(
            configuration: cardPresentPaymentsConfiguration,
            utmProvider: WooCommerceComUTMProvider(
                campaign: Constants.utmCampaign,
                source: Constants.utmSource,
                content: nil,
                siteID: siteID),
            onDismiss: {})
    }()

    lazy var onboardingViewModel: CardPresentPaymentsOnboardingViewModel = {
        let onboardingViewModel = CardPresentPaymentsOnboardingViewModel(useCase: onboardingUseCase)
        onboardingViewModel.showURL = { [weak self] url in
            self?.safariSheetURL = url
        }
        onboardingViewModel.showSupport = { [weak self] in
            self?.presentSupport = true
        }
        return onboardingViewModel
    }()
}

// MARK: - Collect payment

private extension InPersonPaymentsMenuViewModel {
    func collectPayment() {
        let orderViewModel = EditableOrderViewModel(siteID: siteID)
        self.orderViewModel = orderViewModel
        orderViewModel.onFinished = { [weak self] _ in
            self?.dismissPaymentCollection()
        }
        orderViewModel.onFinishAndCollectPayment = { [weak self] order, paymentMethodsViewModel in
            guard let self else { return }
            self.paymentMethodsViewModel = paymentMethodsViewModel
            paymentMethodsNoticeSubscription = paymentMethodsViewModel.notice
                .compactMap { $0 }
                .sink { [weak self] notice in
                    guard let self else { return }
                    switch notice {
                        case .created:
                            dependencies.noticePresenter.enqueue(notice: .init(title: Localization.orderCreated, feedbackType: .success))
                        case .completed:
                            dependencies.noticePresenter.enqueue(notice: .init(title: Localization.orderCompleted, feedbackType: .success))
                        case .error(let description):
                            dependencies.noticePresenter.enqueue(notice: .init(title: description, feedbackType: .error))
                    }
                }
            navigationPath.append(CollectPaymentNavigationDestination.paymentMethods)
        }

        presentCustomAmountAfterDismissingCollectPaymentMigrationSheet = false
        hasPresentedCollectPaymentMigrationSheet = false
        navigationPathBeforePaymentCollection = navigationPath
        navigationPath.append(InPersonPaymentsMenuNavigationDestination.collectPayment)
    }
}

// MARK: - Background onboarding
private extension InPersonPaymentsMenuViewModel {
    func observeOnboardingChanges() {
        guard cardPresentPaymentsConfiguration.isSupportedCountry else {
            return
        }

        onboardingUseCase.statePublisher
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: { [weak self] state in
                self?.refreshAfterNewOnboardingState(state)
        }).store(in: &cancellables)
    }

    func runCardPresentPaymentsOnboardingIfPossible() {
        guard cardPresentPaymentsConfiguration.isSupportedCountry else {
            return
        }

        onboardingUseCase.refreshIfNecessary()
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
            updateManagePaymentGatewaysRow(pluginState: newPluginState)
            shouldDisableManageCardReaders = false
        case .selectPlugin(true):
            // Selected plugin was cleared manually (e.g by tapping in this view on the plugin selection row)
            // No need to show the onboarding notice in this case.
            updateForIncompleteOnboarding(selectedPlugin: nil)
        case .pluginUnsupportedVersion(plugin: let plugin),
                .pluginNotActivated(plugin: let plugin),
                .pluginSetupNotCompleted(plugin: let plugin),
                .pluginInTestModeWithLiveStripeAccount(plugin: let plugin),
                .stripeAccountUnderReview(plugin: let plugin),
                .stripeAccountOverdueRequirement(plugin: let plugin),
                .stripeAccountRejected(plugin: let plugin),
                .codPaymentGatewayNotSetUp(plugin: let plugin),
                .stripeAccountPendingRequirement(plugin: let plugin, deadline: _),
                .countryNotSupportedStripe(plugin: let plugin, countryCode: _):
            updateForIncompleteOnboarding(selectedPlugin: plugin)
            cardPresentPaymentsOnboardingNotice = onboardingNotice
        default:
            updateForIncompleteOnboarding(selectedPlugin: nil)
            cardPresentPaymentsOnboardingNotice = onboardingNotice
            break
        }
        updatePayInPersonToggleSelectedPlugin(from: state)

        backgroundOnboardingInProgress = false
    }

    func updateManagePaymentGatewaysRow(pluginState: CardPresentPaymentsPluginState) {
        let shouldShow = pluginState.available.count > 1
        shouldShowManagePaymentGatewaysRow = shouldShow
        shouldShowPaymentOptionsSection = shouldShow
        selectedPaymentGatewayName = pluginState.preferred.pluginName
        selectedPaymentGatewayPlugin = pluginState.preferred
    }

    func updateForIncompleteOnboarding(selectedPlugin plugin: CardPresentPaymentsPlugin?) {
        shouldDisableManageCardReaders = true
        selectedPaymentGatewayName = plugin?.pluginName
        selectedPaymentGatewayPlugin = plugin
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
                self?.analytics.track(.paymentsMenuOnboardingErrorTapped)
                self?.shouldShowOnboarding = true
            })
    }
}

// MARK: - Card Reader visibility

private extension InPersonPaymentsMenuViewModel {
    func updateCardReadersSection() {
        shouldShowCardReaderSection = isEligibleForCardPresentPayments
    }

    var isEligibleForCardPresentPayments: Bool {
        cardPresentPaymentsConfiguration.isSupportedCountry
    }
}

// MARK: - Tap to Pay visibility

private extension InPersonPaymentsMenuViewModel {
    func updateTapToPaySection() async {
        let deviceSupportsTapToPay = await dependencies.cardReaderSupportDeterminer.deviceSupportsLocalMobileReader()

        shouldShowTapToPaySection = isEligibleForCardPresentPayments &&
            countryEnabledForTapToPay &&
            deviceSupportsTapToPay

        await updateSetUpTryTapToPay()
        await updateTapToPayFeedbackRowVisibility()
    }

    var countryEnabledForTapToPay: Bool {
        cardPresentPaymentsConfiguration.supportedReaders.contains(.appleBuiltIn)
    }

    func updateSetUpTryTapToPay() async {
        let tapToPayWasPreviouslyUsed = await dependencies.cardReaderSupportDeterminer.hasPreviousTapToPayUsage()

        setUpTryOutTapToPayRowTitle = tapToPayWasPreviouslyUsed ? Localization.tryOutTapToPayOnIPhoneRowTitle : Localization.setUpTapToPayOnIPhoneRowTitle
        shouldAlwaysHideSetUpButtonOnAboutTapToPay = tapToPayWasPreviouslyUsed
    }

    func updateTapToPayFeedbackRowVisibility() async {
        guard let firstTapToPayTransactionDate = await dependencies.cardReaderSupportDeterminer.firstTapToPayTransactionDate(),
              let thirtyDaysAgo = Calendar.current.date(byAdding: DateComponents(day: -30), to: Date()) else {
            return self.shouldShowTapToPayFeedbackRow = false
        }

        shouldShowTapToPayFeedbackRow = firstTapToPayTransactionDate >= thirtyDaysAgo
    }
}

// MARK: - Deeplink navigation
extension InPersonPaymentsMenuViewModel: DeepLinkNavigator {
    func navigate(to destination: any DeepLinkDestinationProtocol) {
        guard let paymentsDestination = destination as? PaymentsMenuDestination else {
            return
        }
        switch paymentsDestination {
        case .collectPayment:
            collectPayment()
        case .tapToPay:
            presentSetUpTryOutTapToPay = true
        }
    }
}

/// Destination views that the IPP menu can navigate to.
/// Used in `NavigationPath` for programatic navigation in `NavigationStack` for deeplinking.
enum InPersonPaymentsMenuNavigationDestination {
    case collectPayment
}

enum CollectPaymentNavigationDestination {
    case paymentMethods
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
        static let orderCreated = NSLocalizedString(
            "menu.payments.inPersonPayments.collectPayment.notice.orderCreated",
            value: "🎉 Order created",
            comment: "Notice text after creating an order from In-Person Payments in the Menu"
        )
        static let orderCompleted = NSLocalizedString(
            "menu.payments.inPersonPayments.collectPayment.notice.orderCompleted",
            value: "🎉 Order completed",
            comment: "Notice text after completing a payment order from In-Person Payments in the Menu"
        )
    }
}
