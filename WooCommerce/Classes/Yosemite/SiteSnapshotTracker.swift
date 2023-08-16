import Foundation
import Yosemite

/// Tracks a snapshot of a given site - number of orders, number of products, and the status of various payment gateway plugins.
final class SiteSnapshotTracker {
    private let siteID: Int64
    private let numberOfOrders: Int64
    private let numberOfProducts: Int64
    private let systemPlugins: [SystemPlugin]
    private let analytics: Analytics
    private let userDefaults: UserDefaults

    init(siteID: Int64,
         orderStatuses: [OrderStatus],
         numberOfProducts: Int64,
         systemPlugins: [SystemPlugin],
         analytics: Analytics = ServiceLocator.analytics,
         userDefaults: UserDefaults = .standard) {
        self.siteID = siteID
        numberOfOrders = Int64(orderStatuses.map { $0.total }.reduce(0, +))
        self.numberOfProducts = numberOfProducts
        self.systemPlugins = systemPlugins
        self.analytics = analytics
        self.userDefaults = userDefaults
    }

    /// Tracks the store snapshot if it hasn't been tracked for the same store before.
    func trackIfNeeded() {
        let siteIDsWithSnapshotTracked: [Int64] = userDefaults[.siteIDsWithSnapshotTracked] as? [Int64] ?? []
        guard siteIDsWithSnapshotTracked.contains(siteID) == false else {
            return
        }

        let otherProperties: [String: Any] = [
            "orders_count": numberOfOrders,
            "products_count": numberOfProducts
        ]
        let paymentGatewaySnapshot = PaymentGatewaySnapshot(plugins: systemPlugins)
        let properties: [String: Any] = PaymentGatewaySnapshot.Plugin.allCases.reduce(otherProperties) { partialResult, plugin in
            var newResult = partialResult
            newResult[plugin.rawValue] = paymentGatewaySnapshot.status(of: plugin).rawValue
            return newResult
        }
        analytics.track(.applicationSiteSnapshot, withProperties: properties)

        addSiteIDToUserDefaults(siteIDs: siteIDsWithSnapshotTracked)
    }
}

private extension SiteSnapshotTracker {
    func addSiteIDToUserDefaults(siteIDs: [Int64]) {
        var siteIDs = siteIDs
        siteIDs.append(siteID)
        userDefaults.set(siteIDs, forKey: .siteIDsWithSnapshotTracked)
    }
}

private struct PaymentGatewaySnapshot {
    enum Status: String {
        case active = "installed_and_activated"
        case installed = "installed_and_not_activated"
        case notInstalled = "not_installed"
    }

    enum Plugin: String, CaseIterable {
        case wcPay = "woocommerce-payments"
        case stripe = "woocommerce-gateway-stripe"
        case square = "woocommerce-square"
        case payPal = "woocommerce-gateway-paypal-express-checkout"
    }

    private let plugins: [SystemPlugin]

    init(plugins: [SystemPlugin]) {
        self.plugins = plugins
    }

    func status(of plugin: Plugin) -> Status {
        guard let systemPlugin = plugins.first(where: { $0.plugin.hasPrefix("\(plugin.rawValue)/") }) else {
            return .notInstalled
        }
        return systemPlugin.active ? .active: .installed
    }
}
