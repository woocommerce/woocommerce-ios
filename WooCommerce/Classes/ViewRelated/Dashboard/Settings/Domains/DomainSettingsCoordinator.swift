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

    func start() {
        let settingsNavigationController = WooNavigationController()
        let domainSettings = DomainSettingsHostingController(viewModel: .init(siteID: site.siteID,
                                                                              stores: stores)) { [weak self] in
            self?.showDomainSelector(from: settingsNavigationController)
        }
        settingsNavigationController.pushViewController(domainSettings, animated: false)
        navigationController.present(settingsNavigationController, animated: true)
    }
}

private extension DomainSettingsCoordinator {
    func showDomainSelector(from navigationController: UINavigationController) {
        let viewModel = DomainSelectorViewModel(initialSearchTerm: site.name, dataProvider: PaidDomainSelectorDataProvider())
        let domainSelector = PaidDomainSelectorHostingController(viewModel: viewModel) { domain in
            print("\(domain) - \(domain.productID)")
        } onSupport: {
            // TODO: 8558 - remove support action
        }
        navigationController.show(domainSelector, sender: nil)
    }
}
