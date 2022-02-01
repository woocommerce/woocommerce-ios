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
    private var stripeGatewayIPPEnabled: Bool?

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
        let action = AppSettingsAction.loadStripeInPersonPaymentsSwitchState(onCompletion: { [weak self] result in
            switch result {
            case .success(let stripeGatewayIPPEnabled):
                self?.stripeGatewayIPPEnabled = stripeGatewayIPPEnabled
            default:
                break
            }
            self?.updateState()
        })
        stores.dispatch(action)
    }

    func refresh() {
        if state != .completed {
            state = .loading
        }
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

        let wcPayPlugin = getWCPayPlugin()
        let stripePlugin = getStripePlugin()

        /// If both plugins are active, don't bother initializing the backend nor fetching
        /// accounts. Fall through to updateState so the end user can fix the problem.
        guard !bothPluginsInstalledAndActive(wcPay: wcPayPlugin, stripe: stripePlugin) else {
            self.updateState()
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
        // Country checks
        guard let countryCode = storeCountryCode else {
            DDLogError("[CardPresentPaymentsOnboarding] Couldn't determine country for store")
            return .genericError
        }

        guard isCountrySupported(countryCode: countryCode) else {
            return .countryNotSupported(countryCode: countryCode)
        }

        let wcPay = getWCPayPlugin()
        guard stripeGatewayIPPEnabled == true else {
            return wcPayOnlyOnboardingState(plugin: wcPay)
        }

        let stripe = getStripePlugin()

        // If both the Stripe plugin and WCPay are installed and activated, the user needs
        // to deactivate one: pdfdoF-fW-p2#comment-683
        if bothPluginsInstalledAndActive(wcPay: wcPay, stripe: stripe) {
            return .selectPlugin
        }

        // If only the Stripe extension is installed, skip to checking Stripe activation and version
        if let stripe = stripe,
            wcPayInstalledAndActive(wcPay: wcPay, stripe: stripe) == false {
            return stripeGatewayOnlyOnboardingState(plugin: stripe)
        } else {
            return wcPayOnlyOnboardingState(plugin: wcPay)
        }
    }

    func wcPayOnlyOnboardingState(plugin: SystemPlugin?) -> CardPresentPaymentOnboardingState {
        // Plugin checks
        guard let plugin = plugin else {
            return .pluginNotInstalled
        }
        guard isWCPayVersionSupported(plugin: plugin) else {
            return .pluginUnsupportedVersion(plugin: .wcPay)
        }
        guard plugin.active else {
            return .pluginNotActivated(plugin: .wcPay)
        }

        // Account checks
        return accountChecks(plugin: .wcPay)
    }

    func stripeGatewayOnlyOnboardingState(plugin: SystemPlugin) -> CardPresentPaymentOnboardingState {
        guard isStripeVersionSupported(plugin: plugin) else {
            return .pluginUnsupportedVersion(plugin: .stripe)
        }
        guard plugin.active else {
            return .pluginNotActivated(plugin: .stripe)
        }

        return accountChecks(plugin: .stripe)
    }

    func accountChecks(plugin: CardPresentPaymentsPlugins) -> CardPresentPaymentOnboardingState {
        guard let account = getPaymentGatewayAccount() else {
            return .genericError
        }
        guard isPaymentGatewaySetupCompleted(account: account) else {
            return .pluginSetupNotCompleted
        }
        guard !isPluginInTestModeWithLiveStripeAccount(account: account) else {
            return .pluginInTestModeWithLiveStripeAccount(plugin: plugin)
        }
        guard !isStripeAccountUnderReview(account: account) else {
            return .stripeAccountUnderReview
        }
        guard !isStripeAccountOverdueRequirements(account: account) else {
            return .stripeAccountOverdueRequirement
        }
        guard !isStripeAccountPendingRequirements(account: account) else {
            return .stripeAccountPendingRequirement(deadline: account.currentDeadline)
        }
        guard !isStripeAccountRejected(account: account) else {
            return .stripeAccountRejected
        }
        guard !isInUndefinedState(account: account) else {
            return .genericError
        }

        // If we've gotten this far, tell the Card Present Payment Store which backend to use
        let setAccount = CardPresentPaymentAction.use(paymentGatewayAccount: account)
        stores.dispatch(setAccount)

        return .completed
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

    func isCountrySupported(countryCode: String) -> Bool {
        return CardPresentPaymentsPlugins.wcPay.supportedCountryCodes.contains(countryCode)
    }

    func getWCPayPlugin() -> SystemPlugin? {
        guard let siteID = siteID else {
            return nil
        }
        return storageManager.viewStorage
            .loadSystemPlugin(siteID: siteID, name: CardPresentPaymentsPlugins.wcPay.pluginName)?
            .toReadOnly()
    }

    func getStripePlugin() -> SystemPlugin? {
        guard let siteID = siteID else {
            return nil
        }
        return storageManager.viewStorage
            .loadSystemPlugin(siteID: siteID, name: CardPresentPaymentsPlugins.stripe.pluginName)?
            .toReadOnly()
    }

    func bothPluginsInstalledAndActive(wcPay: SystemPlugin?, stripe: SystemPlugin?) -> Bool {
        guard let wcPay = wcPay, let stripe = stripe else {
            return false
        }

        return wcPay.active && stripe.active
    }

    func wcPayInstalledAndActive(wcPay: SystemPlugin?, stripe: SystemPlugin) -> Bool {
        // If the WCPay plugin is not installed, immediately return false
        guard let wcPay = wcPay else {
            return false
        }

        return wcPay.active
    }

    func isWCPayVersionSupported(plugin: SystemPlugin) -> Bool {
        VersionHelpers.isVersionSupported(version: plugin.version, minimumRequired: CardPresentPaymentsPlugins.wcPay.minimumSupportedPluginVersion)
    }

    func isStripeVersionSupported(plugin: SystemPlugin) -> Bool {
        VersionHelpers.isVersionSupported(version: plugin.version, minimumRequired: CardPresentPaymentsPlugins.stripe.minimumSupportedPluginVersion)
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
