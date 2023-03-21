import Combine
import UIKit
import Yosemite

/// Coordinates navigation for domain settings flow.
final class DomainSettingsCoordinator: Coordinator {
    /// Navigation source to domain settings.
    enum Source {
        /// Initiated from the settings.
        case settings
        /// Initiated from store onboarding in dashboard.
        case dashboardOnboarding
    }

    let navigationController: UINavigationController

    private let site: Site
    private let stores: StoresManager
    private let source: Source
    private let analytics: Analytics
    private weak var presentationControllerDelegate: UIAdaptivePresentationControllerDelegate?

    init(source: Source,
         site: Site,
         navigationController: UINavigationController,
         presentationControllerDelegate: UIAdaptivePresentationControllerDelegate? = nil,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.source = source
        self.site = site
        self.navigationController = navigationController
        self.presentationControllerDelegate = presentationControllerDelegate
        self.stores = stores
        self.analytics = analytics
    }

    @MainActor
    func start() {
        let settingsNavigationController = WooNavigationController()
        let domainSettings = DomainSettingsHostingController(viewModel: .init(siteID: site.siteID,
                                                                              stores: stores)) { [weak self] hasDomainCredit, freeStagingDomain in
            guard let self else { return }
            self.showDomainSelector(from: settingsNavigationController, hasDomainCredit: hasDomainCredit, freeStagingDomain: freeStagingDomain)
        } onClose: { [weak self] in
            self?.navigationController.dismiss(animated: true)
        }
        settingsNavigationController.pushViewController(domainSettings, animated: false)
        settingsNavigationController.presentationController?.delegate = presentationControllerDelegate
        navigationController.present(settingsNavigationController, animated: true)
        analytics.track(event: .DomainSettings.domainSettingsStep(source: source,
                                                                  step: .dashboard))
    }
}

private extension DomainSettingsCoordinator {
    @MainActor
    func showDomainSelector(from navigationController: UINavigationController, hasDomainCredit: Bool, freeStagingDomain: String?) {
        let subtitle = freeStagingDomain
            .map { String(format: Localization.domainSelectorSubtitleFormat, $0) } ?? Localization.domainSelectorSubtitleWithoutFreeStagingDomain
        let viewModel = DomainSelectorViewModel(title: Localization.domainSelectorTitle,
                                                subtitle: subtitle,
                                                initialSearchTerm: site.name,
                                                dataProvider: PaidDomainSelectorDataProvider(stores: stores,
                                                                                             hasDomainCredit: hasDomainCredit))
        let domainSelector = PaidDomainSelectorHostingController(viewModel: viewModel, onDomainSelection: { [weak self] domain in
            guard let self else { return }
            let domainToPurchase = DomainToPurchase(name: domain.name,
                                                    productID: domain.productID,
                                                    supportsPrivacy: domain.supportsPrivacy)
            if hasDomainCredit {
                let contactInfo = try? await self.loadDomainContactInfo()
                self.showContactInfoForm(from: navigationController, contactInfo: contactInfo, domain: domainToPurchase)
            } else {
                do {
                    try await self.createCart(domain: domainToPurchase)
                    self.showWebCheckout(from: navigationController, domain: domainToPurchase)
                } catch {
                    // TODO: 8558 - error handling
                    DDLogError("⛔️ Error creating cart with the selected domain \(domain): \(error)")
                }
            }
        }, onSupport: nil)
        navigationController.show(domainSelector, sender: nil)
        analytics.track(event: .DomainSettings.domainSettingsStep(source: source,
                                                                  step: .domainSelector))
    }

    @MainActor
    func showWebCheckout(from navigationController: UINavigationController, domain: DomainToPurchase) {
        guard let siteURLHost = URLComponents(string: site.url)?.host else {
            // TODO: 8558 - error handling
            DDLogError("⛔️ Error showing web checkout for the selected domain \(domain) because of invalid site slug from site URL \(site.url)")
            return
        }
        let checkoutViewModel = WebCheckoutViewModel(siteSlug: siteURLHost) { [weak self] in
            guard let self else { return }
            self.showSuccessView(from: navigationController, domainName: domain.name)
            self.analytics.track(event: .DomainSettings.domainSettingsCustomDomainPurchaseSuccess(source: self.source,
                                                                                                  useDomainCredit: false))
        }
        let checkoutController = AuthenticatedWebViewController(viewModel: checkoutViewModel)
        navigationController.pushViewController(checkoutController, animated: true)
        analytics.track(event: .DomainSettings.domainSettingsStep(source: source,
                                                                  step: .webCheckout))
    }
}

private extension DomainSettingsCoordinator {
    @MainActor
    func showContactInfoForm(from navigationController: UINavigationController,
                             contactInfo: DomainContactInfo?,
                             domain: DomainToPurchase) {
        let contactInfoForm = DomainContactInfoFormHostingController(viewModel: .init(siteID: site.siteID,
                                                                                      contactInfoToEdit: contactInfo,
                                                                                      domain: domain.name,
                                                                                      source: source,
                                                                                      stores: stores)) { [weak self] contactInfo in
            guard let self else { return }
            do {
                try await self.redeemDomainCredit(domain: domain, contactInfo: contactInfo)
                self.showSuccessView(from: navigationController, domainName: domain.name)
                self.analytics.track(event: .DomainSettings.domainSettingsCustomDomainPurchaseSuccess(source: self.source,
                                                                                                      useDomainCredit: true))
            } catch {
                // TODO: 8558 - error handling
                print("⛔️ Error redeeming domain credit with the selected domain \(domain): \(error)")
                self.analytics.track(event: .DomainSettings.domainSettingsCustomDomainPurchaseFailed(source: self.source,
                                                                                                     useDomainCredit: true,
                                                                                                     error: error))
            }
        }
        navigationController.pushViewController(contactInfoForm, animated: true)
        analytics.track(event: .DomainSettings.domainSettingsStep(source: source,
                                                                  step: .contactInfo))
    }

    @MainActor
    func showSuccessView(from navigationController: UINavigationController,
                         domainName: String) {
        let successController = DomainPurchaseSuccessHostingController(viewModel: .init(domainName: domainName)) {
            navigationController.popToRootViewController(animated: false)
        }
        navigationController.pushViewController(successController, animated: true)
        analytics.track(event: .DomainSettings.domainSettingsStep(source: source,
                                                                  step: .purchaseSuccess))
    }
}

private extension DomainSettingsCoordinator {
    @MainActor
    func createCart(domain: DomainToPurchase) async throws {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(DomainAction.createDomainShoppingCart(siteID: site.siteID,
                                                                  domain: domain) { result in
                continuation.resume(with: result)
            })
        }
    }

    @MainActor
    func loadDomainContactInfo() async throws -> DomainContactInfo {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(DomainAction.loadDomainContactInfo { result in
                continuation.resume(with: result)
            })
        }
    }

    @MainActor
    func redeemDomainCredit(domain: DomainToPurchase, contactInfo: DomainContactInfo) async throws {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(DomainAction.redeemDomainCredit(siteID: site.siteID,
                                                            domain: domain,
                                                            contactInfo: contactInfo) { result in
                continuation.resume(with: result)
            })
        }
    }
}

private extension DomainSettingsCoordinator {
    enum Localization {
        static let domainSelectorTitle = NSLocalizedString(
            "Search domains",
            comment: "Title of the domain selector in domain settings."
        )
        static let domainSelectorSubtitleFormat = NSLocalizedString(
            "The domain purchased will redirect users to **%1$@**",
            comment: "Subtitle of the domain selector in domain settings. %1$@ is the free domain of the site from WordPress.com."
        )
        static let domainSelectorSubtitleWithoutFreeStagingDomain = NSLocalizedString(
            "The domain purchased will redirect users to the current staging domain",
            comment: "Subtitle of the domain selector in domain settings when a free staging domain is unavailable."
        )
    }
}
