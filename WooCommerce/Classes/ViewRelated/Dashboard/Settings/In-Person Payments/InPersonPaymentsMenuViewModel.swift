import Foundation
import Yosemite
import WooFoundation

final class InPersonPaymentsMenuViewModel {
    // MARK: - Dependencies
    struct Dependencies {
        let stores: StoresManager
        let analytics: Analytics

        init(stores: StoresManager = ServiceLocator.stores,
             analytics: Analytics = ServiceLocator.analytics) {
            self.stores = stores
            self.analytics = analytics
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

    let cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration

    init(dependencies: Dependencies = Dependencies(),
         cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration) {
        self.dependencies = dependencies
        self.cardPresentPaymentsConfiguration = cardPresentPaymentsConfiguration
    }

    func viewDidLoad() {
        guard let siteID = siteID else {
            return
        }
        synchronizePaymentGateways(siteID: siteID)
        checkTapToPaySupport(siteID: siteID)
        checkShouldShowTapToPayFeedbackRow(siteID: siteID)
    }

    func refreshTapToPayFeedbackVisibility() {
        guard let siteID = siteID else {
            return
        }
        checkShouldShowTapToPayFeedbackRow(siteID: siteID)
    }

    private func synchronizePaymentGateways(siteID: Int64) {
        let action = PaymentGatewayAction.synchronizePaymentGateways(siteID: siteID, onCompletion: { _ in })
        stores.dispatch(action)
    }

    private func checkTapToPaySupport(siteID: Int64) {
        let action = CardPresentPaymentAction.checkDeviceSupport(
            siteID: siteID,
            cardReaderType: .appleBuiltIn,
            discoveryMethod: .localMobile) { [weak self] deviceSupportsTapToPay in
                guard let self = self else { return }
                self.isEligibleForTapToPayOnIPhone = (
                    self.isEligibleForCardPresentPayments &&
                    self.cardPresentPaymentsConfiguration.supportedReaders.contains { $0 == .appleBuiltIn } &&
                    deviceSupportsTapToPay)
        }
        stores.dispatch(action)
    }

    private func checkShouldShowTapToPayFeedbackRow(siteID: Int64) {
        let action = AppSettingsAction.loadFirstInPersonPaymentsTransactionDate(
            siteID: siteID,
            cardReaderType: .appleBuiltIn) { [weak self] firstTapToPayTransactionDate in
                guard let self = self else { return }
                guard let firstTapToPayTransactionDate = firstTapToPayTransactionDate,
                      let thirtyDaysAgo = Calendar.current.date(byAdding: DateComponents(day: -30), to: Date()) else {
                    return self.shouldShowTapToPayOnIPhoneFeedbackRow = false
                }

                self.shouldShowTapToPayOnIPhoneFeedbackRow = firstTapToPayTransactionDate >= thirtyDaysAgo
        }
        stores.dispatch(action)
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
}

private enum Constants {
    static let utmCampaign = "payments_menu_item"
    static let utmSource = "payments_menu"
}
