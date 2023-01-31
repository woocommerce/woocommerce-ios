import Combine
import UIKit
import Yosemite

/// Coordinates navigation for domain settings flow.
final class DomainSettingsCoordinator: Coordinator {
    /// Navigation source to domain settings.
    enum Source {
        /// Initiated from the settings.
        case settings
    }

    let navigationController: UINavigationController

    private let site: Site
    private let stores: StoresManager
    private let source: Source

    init(source: Source,
         site: Site,
         navigationController: UINavigationController,
         stores: StoresManager = ServiceLocator.stores) {
        self.source = source
        self.site = site
        self.navigationController = navigationController
        self.stores = stores
    }

    @MainActor
    func start() {
        let settingsNavigationController = WooNavigationController()
        let domainSettings = DomainSettingsHostingController(viewModel: .init(siteID: site.siteID,
                                                                              stores: stores)) { [weak self] hasDomainCredit in
            self?.showDomainSelector(from: settingsNavigationController, hasDomainCredit: hasDomainCredit)
        }
        settingsNavigationController.pushViewController(domainSettings, animated: false)
        navigationController.present(settingsNavigationController, animated: true)
    }
}

private extension DomainSettingsCoordinator {
    @MainActor
    func showDomainSelector(from navigationController: UINavigationController, hasDomainCredit: Bool) {
        let viewModel = DomainSelectorViewModel(initialSearchTerm: site.name,
                                                dataProvider: PaidDomainSelectorDataProvider(stores: stores,
                                                                                             hasDomainCredit: hasDomainCredit))
        let domainSelector = PaidDomainSelectorHostingController(viewModel: viewModel) { [weak self] domain in
            guard let self else { return }
            let domainToPurchase = DomainToPurchase(name: domain.name,
                                                    productID: domain.productID,
                                                    supportsPrivacy: domain.supportsPrivacy)
            if hasDomainCredit {
                do {
                    try await self.redeemDomainCredit(domain: domainToPurchase)
                    self.showSuccessView(from: navigationController, domainName: domain.name)
                } catch {
                    // TODO: 8558 - error handling
                    print("⛔️ Error redeeming domain credit with the selected domain \(domain): \(error)")
                }
            } else {
                do {
                    try await self.createCart(domain: domainToPurchase)
                    self.showWebCheckout(from: navigationController, domain: domainToPurchase)
                } catch {
                    // TODO: 8558 - error handling
                    print("⛔️ Error creating cart with the selected domain \(domain): \(error)")
                }
            }
        } onSupport: {
            // TODO: 8558 - remove support action
        }
        navigationController.show(domainSelector, sender: nil)
    }

    func showWebCheckout(from navigationController: UINavigationController, domain: DomainToPurchase) {
        guard let siteURLHost = URLComponents(string: site.url)?.host else {
            // TODO: 8558 - error handling
            print("⛔️ Error showing web checkout for the selected domain \(domain) because of invalid site slug from site URL \(site.url)")
            return
        }
        let checkoutViewModel = WebCheckoutViewModel(siteSlug: siteURLHost) { [weak self] in
            guard let self else { return }
            self.showSuccessView(from: navigationController, domainName: domain.name)
        }
        let checkoutController = AuthenticatedWebViewController(viewModel: checkoutViewModel)
        navigationController.pushViewController(checkoutController, animated: true)
    }

    func showSuccessView(from navigationController: UINavigationController,
                         domainName: String) {
        let successController = DomainPurchaseSuccessHostingController(viewModel: .init(domainName: domainName)) {
            navigationController.popToRootViewController(animated: false)
        }
        navigationController.pushViewController(successController, animated: true)
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
    func redeemDomainCredit(domain: DomainToPurchase) async throws {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(DomainAction.redeemDomainCredit(siteID: site.siteID,
                                                            domain: domain) { result in
                continuation.resume(with: result)
            })
        }
    }
}
