import Foundation
import Yosemite
import WooFoundation

final class InPersonPaymentsMenuViewModel {
    // MARK: - Dependencies
    struct Dependencies {
        let stores: StoresManager
        let analytics: Analytics
        let tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker

        init(stores: StoresManager = ServiceLocator.stores,
             analytics: Analytics = ServiceLocator.analytics,
             tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker? = nil) {
            self.stores = stores
            self.analytics = analytics
            self.tapToPayBadgePromotionChecker = tapToPayBadgePromotionChecker ?? TapToPayBadgePromotionChecker(stores: stores)
        }
    }

    private let dependencies: Dependencies

    private var stores: StoresManager {
        dependencies.stores
    }

    private var analytics: Analytics {
        dependencies.analytics
    }

    // MARK: - Output properties
    @Published var showWebView: AuthenticatedWebViewModel? = nil

    // MARK: - Configuration properties
    private var siteID: Int64? {
        return stores.sessionManager.defaultStoreID
    }

    var isEligibleForCardPresentPayments: Bool {
        cardPresentPaymentsConfiguration.isSupportedCountry
    }

    @Published private(set) var isEligibleForTapToPayOnIPhone: Bool = false
    @Published private(set) var shouldShowTapToPayOnIPhoneFeedbackRow: Bool = false
    @Published private(set) var shouldBadgeTapToPayOnIPhone: Bool = false
    @Published private(set) var depositsOverviewViewModels: [WooPaymentsDepositsCurrencyOverviewViewModel] = []
    @Published private(set) var titleForTapToPayOnIPhone: String = Localization.setUpTapToPayOnIPhoneRowTitle

    let cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration

    init(dependencies: Dependencies = Dependencies(),
         cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration) {
        self.dependencies = dependencies
        self.cardPresentPaymentsConfiguration = cardPresentPaymentsConfiguration
        dependencies.tapToPayBadgePromotionChecker.$shouldShowTapToPayBadges.share().assign(to: &$shouldBadgeTapToPayOnIPhone)
    }

    func viewDidLoad() {
        guard let siteID = siteID else {
            return
        }
        synchronizePaymentGateways(siteID: siteID)
        checkTapToPaySupport(siteID: siteID)
        checkShouldShowTapToPayFeedbackRow(siteID: siteID)
        refreshPropertiesDependentOnTapToPaySetUpState(siteID: siteID)
        registerForNotifications()
        updateDepositsOverview()
    }

    private func synchronizePaymentGateways(siteID: Int64) {
        let action = PaymentGatewayAction.synchronizePaymentGateways(siteID: siteID, onCompletion: { _ in })
        stores.dispatch(action)
    }

    private func checkTapToPaySupport(siteID: Int64) {
        let configuration = cardPresentPaymentsConfiguration
        let action = CardPresentPaymentAction.checkDeviceSupport(
            siteID: siteID,
            cardReaderType: .appleBuiltIn,
            discoveryMethod: .localMobile,
            minimumOperatingSystemVersionOverride: configuration.minimumOperatingSystemVersionForTapToPay) { [weak self] deviceSupportsTapToPay in
                guard let self = self else { return }
                self.isEligibleForTapToPayOnIPhone = (
                    self.isEligibleForCardPresentPayments &&
                    self.cardPresentPaymentsConfiguration.supportedReaders.contains { $0 == .appleBuiltIn } &&
                    deviceSupportsTapToPay)
        }
        stores.dispatch(action)
    }

    private func checkShouldShowTapToPayFeedbackRow(siteID: Int64) {
        Task { @MainActor in
            guard let firstTapToPayTransactionDate = await firstTapToPayTransactionDate(siteID: siteID),
                  let thirtyDaysAgo = Calendar.current.date(byAdding: DateComponents(day: -30), to: Date()) else {
                return self.shouldShowTapToPayOnIPhoneFeedbackRow = false
            }

            self.shouldShowTapToPayOnIPhoneFeedbackRow = firstTapToPayTransactionDate >= thirtyDaysAgo
        }
    }

    @MainActor
    private func firstTapToPayTransactionDate(siteID: Int64) async -> Date? {
        let date = await withCheckedContinuation { continuation in
            let action = AppSettingsAction.loadFirstInPersonPaymentsTransactionDate(
                siteID: siteID,
                cardReaderType: .appleBuiltIn) { firstTapToPayTransactionDate in
                    continuation.resume(with: .success(firstTapToPayTransactionDate))
            }
            stores.dispatch(action)
        }
        return date
    }

    private func refreshPropertiesDependentOnTapToPaySetUpState(siteID: Int64) {
        Task { @MainActor in
            let firstTapToPayTransactionDate = await firstTapToPayTransactionDate(siteID: siteID)
            switch firstTapToPayTransactionDate {
            case .none:
                self.titleForTapToPayOnIPhone = Localization.setUpTapToPayOnIPhoneRowTitle
            case .some:
                self.titleForTapToPayOnIPhone = Localization.tryOutTapToPayOnIPhoneRowTitle
            }
        }
    }

    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshTapToPayRows),
                                               name: .firstInPersonPaymentsTransactionsWereUpdated,
                                               object: nil)
    }

    @objc func refreshTapToPayRows() {
        guard let siteID = siteID else {
            return
        }
        checkShouldShowTapToPayFeedbackRow(siteID: siteID)
        refreshPropertiesDependentOnTapToPaySetUpState(siteID: siteID)
    }

    func orderCardReaderPressed() {
        analytics.track(.paymentsMenuOrderCardReaderTapped)
        showWebView = PurchaseCardReaderWebViewViewModel(configuration: cardPresentPaymentsConfiguration,
                                                         utmProvider: WooCommerceComUTMProvider(
                                                            campaign: Constants.utmCampaign,
                                                            source: Constants.utmSource,
                                                            content: nil,
                                                            siteID: siteID),
                                                         onDismiss: { [weak self] in
            self?.showWebView = nil
        })
    }

    private func updateDepositsOverview() {
        guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.wooPaymentsDepositsOverviewInPaymentsMenu),
            let siteID,
            let credentials = stores.sessionManager.defaultCredentials else {
            return
        }
        let depositService = WooPaymentsDepositService(siteID: siteID,
                                                       credentials: credentials)
        Task {
            let overview = await depositService.fetchDepositsOverview()
            depositsOverviewViewModels = overview.map {
                WooPaymentsDepositsCurrencyOverviewViewModel(overview: $0)
            }
        }
    }

    func depositOverviewViewModel(depositIndex: Int) -> WooPaymentsDepositsCurrencyOverviewViewModel? {
        return depositsOverviewViewModels[depositIndex]
    }

    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: .firstInPersonPaymentsTransactionsWereUpdated,
                                                  object: nil)
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
