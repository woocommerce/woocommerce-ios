import Combine
import Foundation
import Storage
import Yosemite
import Experiments

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

    /// Pending requirements can be skipped so the merchant can continue to collect payments.
    /// Eventually, these become overdue requirements, which cannot be skipped
    ///
    func skipPendingRequirements()

    func selectPlugin(_ selectedPlugin: CardPresentPaymentsPlugin)

    func clearPluginSelection()
}

final class CardPresentPaymentsOnboardingUseCase: CardPresentPaymentsOnboardingUseCaseProtocol, ObservableObject {
    let storageManager: StorageManagerType
    let stores: StoresManager
    let configurationLoader: CardPresentConfigurationLoader
    let featureFlagService: FeatureFlagService
    private let cardPresentPluginsDataProvider: CardPresentPluginsDataProvider
    private let cardPresentPaymentOnboardingStateCache: CardPresentPaymentOnboardingStateCache
    private var preferredPluginLocal: CardPresentPaymentsPlugin?
    private var wasCashOnDeliveryStepSkipped: Bool = false
    private var pendingRequirementsStepSkipped: Bool = false

    @Published var state: CardPresentPaymentOnboardingState = .loading

    var statePublisher: Published<CardPresentPaymentOnboardingState>.Publisher {
        $state
    }
    private var cancellables: [AnyCancellable] = []

    init(
        storageManager: StorageManagerType = ServiceLocator.storageManager,
        stores: StoresManager = ServiceLocator.stores,
        featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
        cardPresentPaymentOnboardingStateCache: CardPresentPaymentOnboardingStateCache = CardPresentPaymentOnboardingStateCache.shared
    ) {
        self.storageManager = storageManager
        self.stores = stores
        self.configurationLoader = .init(stores: stores)
        self.cardPresentPluginsDataProvider = .init(storageManager: storageManager, stores: stores, configuration: configurationLoader.configuration)
        self.featureFlagService = featureFlagService
        self.cardPresentPaymentOnboardingStateCache = cardPresentPaymentOnboardingStateCache

        // Rely on cached value if there's any
        if let cachedValue = cardPresentPaymentOnboardingStateCache.value {
            state = cachedValue
        } else {
            updateState()
        }
    }

    func refresh() {
        if !state.isCompleted {
            state = .loading
        }
        refreshOnboardingState()
    }

    func skipPendingRequirements() {
        pendingRequirementsStepSkipped = true
        refresh()
    }

    func forceRefresh() {
        state = .loading
        refreshOnboardingState()
    }

    func refreshIfNecessary() {
        if let cachedValue = cardPresentPaymentOnboardingStateCache.value,
           cachedValue.isCompleted {
            if cachedValue != state {
                state = cachedValue
            }
        } else {
            refresh()
        }
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
            guard let self = self else {
                return
            }

            self.updateState()
            CardPresentPaymentOnboardingStateCache.shared.update(self.state)
        }
        stores.dispatch(paymentGatewayAccountsAction)
    }

    func updateState() {
        state = checkOnboardingState()
    }

    func selectPlugin(_ selectedPlugin: CardPresentPaymentsPlugin) {
        assert(state.isSelectPlugin)

        preferredPluginLocal = selectedPlugin
        deferredSaveSelectedPluginWhenOnboardingComplete(selectedPlugin: selectedPlugin)

        updateState()
        CardPresentPaymentOnboardingStateCache.shared.update(self.state)
    }

    private func deferredSaveSelectedPluginWhenOnboardingComplete(selectedPlugin: CardPresentPaymentsPlugin) {
        $state.share().sink { [weak self] newState in
            if case .completed(let pluginState) = newState,
               pluginState.preferred == selectedPlugin {
                self?.savePreferredPlugin(selectedPlugin)
            }
        }
        .store(in: &cancellables)
    }

    func clearPluginSelection() {
        guard let siteID = siteID else {
            return
        }
        preferredPluginLocal = nil
        let action = AppSettingsAction.forgetPreferredInPersonPaymentGateway(siteID: siteID)
        stores.dispatch(action)

        var newState = checkOnboardingState()
        if case .selectPlugin = newState {
            newState = .selectPlugin(pluginSelectionWasCleared: true)
        }

        state = newState
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
        checkIfCashOnDeliveryStepSkipped()

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
        if preferredPluginLocal == nil {
            preferredPluginLocal = storedPreferredPlugin
        }

        if !isStripeSupportedInCountry {
            return wcPayOnlyOnboardingState(plugin: wcPay)
        }

        guard let preferredPlugin = preferredPluginLocal else {
            return .selectPlugin(pluginSelectionWasCleared: false)
        }

        let state = onboardingStateForPlugin(preferredPlugin, wcPay: wcPay, stripe: stripe)
        return augmentStateWithAvailablePlugins(state: state, available: [.wcPay, .stripe])
    }

    func onboardingStateForPlugin(_ plugin: CardPresentPaymentsPlugin, wcPay: SystemPlugin, stripe: SystemPlugin) -> CardPresentPaymentOnboardingState {
        switch plugin {
        case .wcPay:
            return wcPayOnlyOnboardingState(plugin: wcPay)
        case .stripe:
            return stripeGatewayOnlyOnboardingState(plugin: stripe)
        }
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
        guard let account = getPaymentGatewayAccount(plugin: plugin) else {
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
        guard !shouldShowPendingRequirements(account: account) else {
            return .stripeAccountPendingRequirement(plugin: plugin, deadline: account.currentDeadline)
        }
        guard !isStripeAccountRejected(account: account) else {
            return .stripeAccountRejected(plugin: plugin)
        }
        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.promptToEnableCodInIppOnboarding) {
            if shouldShowCashOnDeliveryStep {
                return .codPaymentGatewayNotSetUp(plugin: plugin)
            }
        }
        guard accountStatusAllowedForCardPresentPayments(account: account) else {
            return .genericError
        }

        // If we've gotten this far, tell the Card Present Payment Store which account to use
        let setAccount = CardPresentPaymentAction.use(paymentGatewayAccount: account)
        stores.dispatch(setAccount)

        // Also reset the skipped pending requirements step, so that it can be shown again in the next flow
        pendingRequirementsStepSkipped = false
        return .completed(plugin: CardPresentPaymentsPluginState(plugin: plugin))
    }

    func augmentStateWithAvailablePlugins(
        state: CardPresentPaymentOnboardingState,
        available: [CardPresentPaymentsPlugin]
    ) -> CardPresentPaymentOnboardingState {
        guard case .completed(let pluginState) = state else {
            return state
        }

        return .completed(plugin: .init(preferred: pluginState.preferred, available: available))
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

    var storedPreferredPlugin: CardPresentPaymentsPlugin? {
        guard let siteID = siteID else {
            return nil
        }

        var gatewayID: String?
        let action = AppSettingsAction.getPreferredInPersonPaymentGateway(siteID: siteID) {
            gatewayID = $0
        }
        stores.dispatch(action)
        return gatewayID.flatMap(CardPresentPaymentsPlugin.with(gatewayID:))
    }

    func savePreferredPlugin(_ plugin: CardPresentPaymentsPlugin) {
        guard let siteID = siteID else {
            return
        }
        let action = AppSettingsAction.setPreferredInPersonPaymentGateway(siteID: siteID, gateway: plugin.gatewayID)
        stores.dispatch(action)
    }

    var isStripeSupportedInCountry: Bool {
        configurationLoader.configuration.paymentGateways.contains(StripeAccount.gatewayID)
    }

    // Note: This counts on synchronizeStoreCountryAndPlugins having been called to get
    // the appropriate account for the site, be that Stripe or WCPay
    func getPaymentGatewayAccount(plugin: CardPresentPaymentsPlugin) -> PaymentGatewayAccount? {
        guard let siteID = siteID else {
            return nil
        }
        return storageManager.viewStorage
            .loadPaymentGatewayAccounts(siteID: siteID)
            .first(where: { $0.isCardPresentEligible && $0.gatewayID == plugin.gatewayID })?
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

    func shouldShowPendingRequirements(account: PaymentGatewayAccount) -> Bool {
        isStripeAccountPendingRequirements(account: account) && !pendingRequirementsStepSkipped
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

    var shouldShowCashOnDeliveryStep: Bool {
        !isCashOnDeliverySetUp() && !wasCashOnDeliveryStepSkipped
    }

    func checkIfCashOnDeliveryStepSkipped() {
        guard let siteID = siteID else {
            return
        }

        let action = AppSettingsAction.getSkippedCashOnDeliveryOnboardingStep(siteID: siteID) { [weak self] skipped in
            self?.wasCashOnDeliveryStepSkipped = skipped
        }

        stores.dispatch(action)
    }

    func isCashOnDeliverySetUp() -> Bool {
        guard let siteID = siteID,
              let codGateway = storageManager.viewStorage.loadPaymentGateway(siteID: siteID, gatewayID: "cod")?.toReadOnly()
        else {
            return false
        }

        return codGateway.enabled
    }

    func accountStatusAllowedForCardPresentPayments(account: PaymentGatewayAccount) -> Bool {
        account.wcpayStatus == .complete ||
        account.wcpayStatus == .restrictedSoon
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
