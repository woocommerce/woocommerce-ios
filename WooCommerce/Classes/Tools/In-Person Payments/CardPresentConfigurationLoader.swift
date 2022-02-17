import Combine
import Foundation
import Storage
import Yosemite

final class CardPresentConfigurationLoader: CardPresentConfigurationLoaderInterface {
    @Published var configuration: CardPresentPaymentsConfiguration = .unsupported
    @Published var state: CardPresentPaymentOnboardingState = .loading

    @Published private var pluginsResultsController: ResultsController<StorageSystemPlugin>? = nil
    private var activePluginsSubject = CurrentValueSubject<[Yosemite.SystemPlugin], Never>([])

    @Published private var accountResultsController: ResultsController<StoragePaymentGatewayAccount>? = nil
    private var accountSubject = CurrentValueSubject<[Yosemite.PaymentGatewayAccount], Never>([])

    init(
        appSettingsService: GeneralAppSettingsService = ServiceLocator.appSettingsService,
        sessionManager: SessionManagerProtocol = ServiceLocator.stores.sessionManager,
        storageManager: StorageManagerType = ServiceLocator.storageManager
    ) {
        super.init()
        let stripePublisher = appSettingsService
            .publisher(for: \.isStripeInPersonPaymentsSwitchEnabled)

        let canadaPublisher = appSettingsService
            .publisher(for: \.isCanadaInPersonPaymentsSwitchEnabled)

        stripePublisher.combineLatest(canadaPublisher).map { (stripeGatewayIPPEnabled, canadaIPPEnabled) in
            CardPresentPaymentsConfiguration(
                // TODO: observe changes to site address
                country: SiteAddress().countryCode,
                stripeEnabled: stripeGatewayIPPEnabled,
                canadaEnabled: canadaIPPEnabled
            )
        }
        .assign(to: &$configuration)

        let siteIdPublisher = sessionManager.defaultSite
            .publisher
            .map(\.siteID)
            .share()

        siteIdPublisher.combineLatest($configuration)
            .map { [weak self] (siteID, configuration) in
                self?.pluginResultsController(siteID: siteID, supportedGateways: configuration.paymentGateways, storageManager: storageManager)
            }
            .assign(to: &$pluginsResultsController)

        siteIdPublisher.combineLatest($configuration)
            .map { [weak self] (siteID, configuration) in
                self?.accountResultsController(siteID: siteID, supportedGateways: configuration.paymentGateways, storageManager: storageManager)
            }
            .assign(to: &$accountResultsController)

        $configuration
            .combineLatest(activePluginsSubject, accountSubject)
            .map { [weak self] (configuration, activePlugins, accounts) in
                self?.checkOnboardingState(configuration: configuration, activePlugins: activePlugins, accounts: accounts) ?? .loading
            }
            .assign(to: &$state)
    }

    func pluginResultsController(siteID: Int64, supportedGateways: [String], storageManager: StorageManagerType) -> ResultsController<StorageSystemPlugin> {
        let pluginPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "name = %@", CardPresentPaymentsPlugins.wcPay.pluginName),
            NSPredicate(format: "name = %@", CardPresentPaymentsPlugins.stripe.pluginName),
        ])
        let sitePredicate = NSPredicate(format: "siteID = %lld", siteID)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [sitePredicate, pluginPredicate])

        let controller = ResultsController<StorageSystemPlugin>(storageManager: storageManager, matching: predicate, sortedBy: [])
        controller.onDidChangeContent = { [activePluginsSubject, weak controller] in
            activePluginsSubject.send(controller?.fetchedObjects ?? [])
        }
        try? controller.performFetch()
        return controller
    }

    func accountResultsController(
        siteID: Int64,
        supportedGateways: [String],
        storageManager: StorageManagerType
    ) -> ResultsController<StoragePaymentGatewayAccount> {
        let pluginPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            NSPredicate(format: "gatewayID = %@", CardPresentPaymentsPlugins.wcPay.pluginName),
            NSPredicate(format: "gatewayID = %@", CardPresentPaymentsPlugins.stripe.pluginName),
        ])
        let sitePredicate = NSPredicate(format: "siteID = %lld", siteID)
        let eligiblePredicate = NSPredicate(format: "isCardPresentEligible = %@", true)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [sitePredicate, pluginPredicate, eligiblePredicate])

        let controller = ResultsController<StoragePaymentGatewayAccount>(storageManager: storageManager, matching: predicate, sortedBy: [])
        controller.onDidChangeContent = { [accountSubject, weak controller] in
            accountSubject.send(controller?.fetchedObjects ?? [])
        }
        try? controller.performFetch()
        return controller
    }
}

private extension CardPresentConfigurationLoader {
    func checkOnboardingState(
        configuration: CardPresentPaymentsConfiguration,
        activePlugins: [Yosemite.SystemPlugin],
        accounts: [Yosemite.PaymentGatewayAccount]
    ) -> CardPresentPaymentOnboardingState {
        guard configuration.isSupportedCountry else {
            return .countryNotSupported(countryCode: configuration.countryCode)
        }

        let wcPay = activePlugins.first(where: { $0.name == CardPresentPaymentsPlugins.wcPay.pluginName })
        guard configuration.paymentGateways.contains(StripeAccount.gatewayID) == true else {
            return wcPayOnlyOnboardingState(plugin: wcPay, accounts: accounts)
        }

        let stripe = activePlugins.first(where: { $0.name == CardPresentPaymentsPlugins.stripe.pluginName })

        // If both the Stripe plugin and WCPay are installed and activated, the user needs
        // to deactivate one: pdfdoF-fW-p2#comment-683
        if bothPluginsInstalledAndActive(wcPay: wcPay, stripe: stripe) {
            return .selectPlugin
        }

        // If only the Stripe extension is installed, skip to checking Stripe activation and version
        if let stripe = stripe,
            wcPayInstalledAndActive(wcPay: wcPay, stripe: stripe) == false {
            return stripeGatewayOnlyOnboardingState(plugin: stripe, accounts: accounts)
        } else {
            return wcPayOnlyOnboardingState(plugin: wcPay, accounts: accounts)
        }
    }

    func wcPayOnlyOnboardingState(plugin: Yosemite.SystemPlugin?, accounts: [Yosemite.PaymentGatewayAccount]) -> CardPresentPaymentOnboardingState {
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
        return accountChecks(plugin: .wcPay, accounts: accounts)
    }

    func stripeGatewayOnlyOnboardingState(plugin: Yosemite.SystemPlugin, accounts: [Yosemite.PaymentGatewayAccount]) -> CardPresentPaymentOnboardingState {
        guard isStripeVersionSupported(plugin: plugin) else {
            return .pluginUnsupportedVersion(plugin: .stripe)
        }
        guard plugin.active else {
            return .pluginNotActivated(plugin: .stripe)
        }

        return accountChecks(plugin: .stripe, accounts: accounts)
    }

    func accountChecks(plugin: CardPresentPaymentsPlugins, accounts: [Yosemite.PaymentGatewayAccount]) -> CardPresentPaymentOnboardingState {
        guard let account = accounts.first(where: { $0.gatewayID == plugin.pluginName }) else {
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

        return .completed(account)
    }

    func bothPluginsInstalledAndActive(wcPay: Yosemite.SystemPlugin?, stripe: Yosemite.SystemPlugin?) -> Bool {
        guard let wcPay = wcPay, let stripe = stripe else {
            return false
        }

        return wcPay.active && stripe.active
    }

    func wcPayInstalledAndActive(wcPay: Yosemite.SystemPlugin?, stripe: Yosemite.SystemPlugin) -> Bool {
        // If the WCPay plugin is not installed, immediately return false
        guard let wcPay = wcPay else {
            return false
        }

        return wcPay.active
    }

    func isWCPayVersionSupported(plugin: Yosemite.SystemPlugin) -> Bool {
        VersionHelpers.isVersionSupported(version: plugin.version, minimumRequired: CardPresentPaymentsPlugins.wcPay.minimumSupportedPluginVersion)
    }

    func isStripeVersionSupported(plugin: Yosemite.SystemPlugin) -> Bool {
        VersionHelpers.isVersionSupported(version: plugin.version, minimumRequired: CardPresentPaymentsPlugins.stripe.minimumSupportedPluginVersion)
    }

    func isPaymentGatewaySetupCompleted(account: Yosemite.PaymentGatewayAccount) -> Bool {
        account.wcpayStatus != .noAccount
    }

    func isPluginInTestModeWithLiveStripeAccount(account: Yosemite.PaymentGatewayAccount) -> Bool {
        account.isLive && account.isInTestMode
    }

    func isStripeAccountUnderReview(account: Yosemite.PaymentGatewayAccount) -> Bool {
        account.wcpayStatus == .restricted
            && !account.hasPendingRequirements
            && !account.hasOverdueRequirements
    }

    func isStripeAccountPendingRequirements(account: Yosemite.PaymentGatewayAccount) -> Bool {
        account.wcpayStatus == .restricted
            && account.hasPendingRequirements
            || account.wcpayStatus == .restrictedSoon
    }

    func isStripeAccountOverdueRequirements(account: Yosemite.PaymentGatewayAccount) -> Bool {
        account.wcpayStatus == .restricted && account.hasOverdueRequirements
    }

    func isStripeAccountRejected(account: Yosemite.PaymentGatewayAccount) -> Bool {
        account.wcpayStatus == .rejectedFraud
            || account.wcpayStatus == .rejectedListed
            || account.wcpayStatus == .rejectedTermsOfService
            || account.wcpayStatus == .rejectedOther
    }

    func isInUndefinedState(account: Yosemite.PaymentGatewayAccount) -> Bool {
        account.wcpayStatus != .complete
    }

    func isNetworkError(_ error: Error) -> Bool {
        (error as NSError).domain == NSURLErrorDomain
    }
}

private extension Yosemite.PaymentGatewayAccount {
    var wcpayStatus: WCPayAccountStatusEnum {
        .init(rawValue: status)
    }
}
