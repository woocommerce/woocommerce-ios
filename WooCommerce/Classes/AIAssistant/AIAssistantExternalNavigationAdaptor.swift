import Foundation
import UIKit
import Yosemite
import CocoaLumberjackSwift
import protocol WooAIAssistant.AssistantExternalNavigationProviding

/// `StoresManager` isn't declared `Sendable`, but the production instance is constructed once at launch.
/// The `siteID` argument on each protocol method is intentionally ignored; the bound siteID wins so a
/// model emitted for a stale session can't push detail into the wrong store.
struct AIAssistantExternalNavigationAdaptor: AssistantExternalNavigationProviding, @unchecked Sendable {

    private let boundSiteID: Int64
    private let navigationHost: AIAssistantNavigationHost
    private let stores: StoresManager

    init(siteID: Int64,
         navigationHost: AIAssistantNavigationHost,
         stores: StoresManager = ServiceLocator.stores) {
        self.boundSiteID = siteID
        self.navigationHost = navigationHost
        self.stores = stores
    }

    func openOrder(siteID: Int64, orderID: Int64) {
        let boundSiteID = self.boundSiteID
        let navigationHost = self.navigationHost
        let stores = self.stores
        Task { @MainActor in
            guard let order = await Self.fetchOrder(orderID: orderID, boundSiteID: boundSiteID, stores: stores) else { return }
            let viewModel = OrderDetailsViewModel(order: order)
            let detailVC = OrderDetailsViewController(viewModel: viewModel)
            Self.push(detailVC, navigationHost: navigationHost)
        }
    }

    func openProduct(siteID: Int64, productID: Int64) {
        let boundSiteID = self.boundSiteID
        let navigationHost = self.navigationHost
        let stores = self.stores
        Task { @MainActor in
            guard let product = await Self.fetchProduct(productID: productID, boundSiteID: boundSiteID, stores: stores) else { return }
            let detailVC = ProductDetailsFactory.productDetails(product: product,
                                                                 presentationStyle: .navigationStack,
                                                                 forceReadOnly: false)
            Self.push(detailVC, navigationHost: navigationHost)
        }
    }

    func openCustomer(siteID: Int64, customerID: Int64) {
        // Customer detail is currently no-op: the existing detail VM is wired against
        // `WCAnalyticsCustomer` aggregate fields the chat doesn't have. Phase 2.
    }

    @MainActor
    private static func push(_ viewController: UIViewController, navigationHost: AIAssistantNavigationHost) {
        guard let nav = navigationHost.navigationController else { return }
        nav.pushViewController(viewController, animated: true)
    }

    private static func fetchOrder(orderID: Int64, boundSiteID: Int64, stores: StoresManager) async -> Order? {
        await withCheckedContinuation { continuation in
            let action = OrderAction.retrieveOrderRemotely(siteID: boundSiteID, orderID: orderID) { result in
                continuation.resume(returning: unwrap(result, label: "order"))
            }
            stores.dispatch(action)
        }
    }

    private static func fetchProduct(productID: Int64, boundSiteID: Int64, stores: StoresManager) async -> Product? {
        await withCheckedContinuation { continuation in
            let action = ProductAction.retrieveProduct(siteID: boundSiteID, productID: productID) { result in
                continuation.resume(returning: unwrap(result, label: "product"))
            }
            stores.dispatch(action)
        }
    }

    private static func unwrap<T, E: Error>(_ result: Result<T, E>, label: String) -> T? {
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            DDLogError("⛔️ AIAssistantExternalNavigationAdaptor failed to fetch \(label): \(error)")
            return nil
        }
    }
}
