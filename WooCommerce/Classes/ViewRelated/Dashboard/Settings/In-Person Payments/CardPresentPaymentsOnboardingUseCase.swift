import Combine
import Foundation
import Storage
import Yosemite

private typealias SystemPlugin = Yosemite.SystemPlugin
private typealias PaymentGatewayAccount = Yosemite.PaymentGatewayAccount

/// Protocol for `CardPresentPaymentsOnboardingUseCase`.
/// Right now, only used for testing.
///
protocol CardPresentPaymentsOnboardingUseCaseProtocol {
    /// Current store onboarding state.
    ///
    var state: CardPresentPaymentOnboardingState { get set }

    /// Store onboarding state publisher.
    ///
    var statePublisher: Published<CardPresentPaymentOnboardingState>.Publisher { get }

    /// Resynchronize the onboarding state if needed.
    ///
    func refresh()

    /// Update the onboarding state with the latest synced values.
    ///
    func updateState()
}

final class CardPresentPaymentsOnboardingUseCase: CardPresentPaymentsOnboardingUseCaseProtocol, ObservableObject {
    let storageManager: StorageManagerType
    let stores: StoresManager
    let configurationLoader: CardPresentConfigurationLoader
    private let cardPresentPluginsDataProvider: CardPresentPluginsDataProvider

    @Published var state: CardPresentPaymentOnboardingState = .loading

    var statePublisher: Published<CardPresentPaymentOnboardingState>.Publisher {
        $state
    }

    init(
        storageManager: StorageManagerType = ServiceLocator.storageManager,
        stores: StoresManager = ServiceLocator.stores
    ) {
        self.storageManager = storageManager
        self.stores = stores
        self.configurationLoader = .init(stores: stores)
        self.cardPresentPluginsDataProvider = .init(storageManager: storageManager, stores: stores, configuration: configurationLoader.configuration)

        updateState()
    }

    func refresh() {
        if !state.isCompleted {
            state = .loading
        }
        refreshOnboardingState()
    }

    func forceRefresh() {
        state = .loading
        refreshOnboardingState()
    }

    private func refreshOnboardingState() {
        synchronizeStoreCountryAndPlugins { [weak self] in
            self?.updateAccounts()
        }
    }

    /// We need to sync payment gateway accounts to see if the payment gateway is set up correctly.
    /// But first we also need to prompt the CardPresentPaymentStore to use the right backend based on the active plugin.
    ///
    func updateAccounts() {
        guard let siteID = siteID else {
            return
        }

        let paymentGatewayAccountsAction = CardPresentPaymentAction.loadAccounts(siteID: siteID) { [weak self] result in
            self?.updateState()
        }
        stores.dispatch(paymentGatewayAccountsAction)
    }

    func updateState() {
        state = checkOnboardingState()
    }
}

// MARK: - Internal state
//
private extension CardPresentPaymentsOnboardingUseCase {
    func synchronizeStoreCountryAndPlugins(completion: () -> Void) {
        guard let siteID = siteID else {
            completion()
            return
        }

        let group = DispatchGroup()
        var errors = [Error]()

        // We need to sync settings to check the store's country
        let settingsAction = SettingAction.synchronizeGeneralSiteSettings(siteID: siteID) { error in
            if let error = error {
                DDLogError("[CardPresentPaymentsOnboarding] Error syncing site settings: \(error)")
                errors.append(error)
            }
            group.leave()
        }
        group.enter()
        stores.dispatch(settingsAction)

        // We need to sync plugins to see which CPP-supporting plugins are installed, up to date, and active
        let systemPluginsAction = SystemStatusAction.synchronizeSystemPlugins(siteID: siteID) { result in
            if case let .failure(error) = result {
                DDLogError("[CardPresentPaymentsOnboarding] Error syncing system plugins: \(error)")
                errors.append(error)
            }
            group.leave()
        }
        group.enter()
        stores.dispatch(systemPluginsAction)

        group.notify(queue: .main, execute: { [weak self] in
            guard let self = self else { return }
            if errors.isNotEmpty,
               errors.contains(where: self.isNetworkError(_:)) {
                self.state = .noConnectionError
            } else {
                self.updateAccounts()
            }
        })
    }

    func checkOnboardingState() -> CardPresentPaymentOnboardingState {
        guard let countryCode = storeCountryCode else {
            DDLogError("[CardPresentPaymentsOnboarding] Couldn't determine country for store")
            return .genericError
        }

        let configuration = configurationLoader.configuration

        let wcPay = cardPresentPluginsDataProvider.getWCPayPlugin()
        let stripe = cardPresentPluginsDataProvider.getStripePlugin()

        // If isSupportedCountry is false, IPP is not supported in the country through any
        // payment gateway
        guard configuration.isSupportedCountry else {
            return .countryNotSupported(countryCode: countryCode)
        }

        switch (wcPay, stripe) {
        case (.some(let wcPay), nil):
            return wcPayOnlyOnboardingState(plugin: wcPay)
        case (nil, .some(let stripe)):
            return stripeGatewayOnlyOnboardingState(plugin: stripe)
        case (.some(let wcPay), .some(let stripe)):
            return bothPluginsInstalledOnboardingState(wcPay: wcPay, stripe: stripe)
        case (nil, nil):
            return .pluginNotInstalled
        }
    }

    func bothPluginsInstalledOnboardingState(wcPay: SystemPlugin, stripe: SystemPlugin) -> CardPresentPaymentOnboardingState {
        switch (wcPay.active, stripe.active) {
        case (true, true):
            return bothPluginsInstalledAndActiveOnboardingState(wcPay: wcPay, stripe: stripe)
        case (true, false):
            return wcPayOnlyOnboardingState(plugin: wcPay)
        case (false, true):
            return stripeGatewayOnlyOnboardingState(plugin: stripe)
        case (false, false):
            return .pluginNotActivated(plugin: .wcPay)
        }
    }

    func bothPluginsInstalledAndActiveOnboardingState(wcPay: SystemPlugin, stripe: SystemPlugin) -> CardPresentPaymentOnboardingState {
        if !isStripeSupportedInCountry {
            return .pluginShouldBeDeactivated(plugin: .stripe)
        }

        return .selectPlugin
    }

    func wcPayOnlyOnboardingState(plugin: SystemPlugin) -> CardPresentPaymentOnboardingState {
        // Plugin checks
        guard cardPresentPluginsDataProvider.isWCPayVersionSupported(plugin: plugin)
        else {
            return .pluginUnsupportedVersion(plugin: .wcPay)
        }
        guard plugin.active else {
            return .pluginNotActivated(plugin: .wcPay)
        }

        // Account checks
        return accountChecks(plugin: .wcPay)
    }

    func stripeGatewayOnlyOnboardingState(plugin: SystemPlugin) -> CardPresentPaymentOnboardingState {
        guard isStripeSupportedInCountry else {
            guard let countryCode = storeCountryCode else {
                DDLogError("[CardPresentPaymentsOnboarding] Couldn't determine country for store")
                return .genericError
            }
            return .countryNotSupportedStripe(plugin: .stripe, countryCode: countryCode)
        }

        guard cardPresentPluginsDataProvider.isStripeVersionSupported(plugin: plugin)
        else {
            return .pluginUnsupportedVersion(plugin: .stripe)
        }
        guard plugin.active else {
            return .pluginNotActivated(plugin: .stripe)
        }

        return accountChecks(plugin: .stripe)
    }

    func accountChecks(plugin: CardPresentPaymentsPlugin) -> CardPresentPaymentOnboardingState {
        guard let account = getPaymentGatewayAccount() else {
            /// Active plugin but unable to fetch an account? Prompt the merchant to finish setting it up.
            return .pluginSetupNotCompleted(plugin: plugin)
        }
        guard isPaymentGatewaySetupCompleted(account: account) else {
            return .pluginSetupNotCompleted(plugin: plugin)
        }
        guard !isPluginInTestModeWithLiveStripeAccount(account: account) else {
            return .pluginInTestModeWithLiveStripeAccount(plugin: plugin)
        }
        guard !isStripeAccountUnderReview(account: account) else {
            return .stripeAccountUnderReview(plugin: plugin)
        }
        guard !isStripeAccountOverdueRequirements(account: account) else {
            return .stripeAccountOverdueRequirement(plugin: plugin)
        }
        guard !isStripeAccountPendingRequirements(account: account) else {
            return .stripeAccountPendingRequirement(plugin: plugin, deadline: account.currentDeadline)
        }
        guard !isStripeAccountRejected(account: account) else {
            return .stripeAccountRejected(plugin: plugin)
        }
        guard !isInUndefinedState(account: account) else {
            return .genericError
        }

        // If we've gotten this far, tell the Card Present Payment Store which backend to use
        let setAccount = CardPresentPaymentAction.use(paymentGatewayAccount: account)
        stores.dispatch(setAccount)

        return .completed(plugin: plugin)
    }
}

// MARK: - Convenience methods
private extension CardPresentPaymentsOnboardingUseCase {
    var siteID: Int64? {
        stores.sessionManager.defaultStoreID
    }

    var storeCountryCode: String? {
        let siteSettings = SelectedSiteSettings(stores: stores, storageManager: storageManager).siteSettings
        let storeAddress = SiteAddress(siteSettings: siteSettings)
        let storeCountryCode = storeAddress.countryCode

        return storeCountryCode.nonEmptyString()
    }

    var isStripeSupportedInCountry: Bool {
        configurationLoader.configuration.paymentGateways.contains(StripeAccount.gatewayID)
    }

    // Note: This counts on synchronizeStoreCountryAndPlugins having been called to get
    // the appropriate account for the site, be that Stripe or WCPay
    func getPaymentGatewayAccount() -> PaymentGatewayAccount? {
        guard let siteID = siteID else {
            return nil
        }
        return storageManager.viewStorage
            .loadPaymentGatewayAccounts(siteID: siteID)
            .first(where: \.isCardPresentEligible)?
            .toReadOnly()
    }

    func isPaymentGatewaySetupCompleted(account: PaymentGatewayAccount) -> Bool {
        account.wcpayStatus != .noAccount
    }

    func isPluginInTestModeWithLiveStripeAccount(account: PaymentGatewayAccount) -> Bool {
        account.isLive && account.isInTestMode
    }

    func isStripeAccountUnderReview(account: PaymentGatewayAccount) -> Bool {
        account.wcpayStatus == .restricted
            && !account.hasPendingRequirements
            && !account.hasOverdueRequirements
    }

    func isStripeAccountPendingRequirements(account: PaymentGatewayAccount) -> Bool {
        account.wcpayStatus == .restricted
            && account.hasPendingRequirements
            || account.wcpayStatus == .restrictedSoon
    }

    func isStripeAccountOverdueRequirements(account: PaymentGatewayAccount) -> Bool {
        account.wcpayStatus == .restricted && account.hasOverdueRequirements
    }

    func isStripeAccountRejected(account: PaymentGatewayAccount) -> Bool {
        account.wcpayStatus == .rejectedFraud
            || account.wcpayStatus == .rejectedListed
            || account.wcpayStatus == .rejectedTermsOfService
            || account.wcpayStatus == .rejectedOther
    }

    func isInUndefinedState(account: PaymentGatewayAccount) -> Bool {
        account.wcpayStatus != .complete
    }

    func isNetworkError(_ error: Error) -> Bool {
        (error as NSError).domain == NSURLErrorDomain
    }
}

// MARK: -

private extension PaymentGatewayAccount {
    var wcpayStatus: WCPayAccountStatusEnum {
        .init(rawValue: status)
    }
}
