import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// Tracks a snapshot of a given site - number of orders, number of products, and the status of various payment gateway plugins.
final class SiteSnapshotTracker {
    private let siteID: Int64
    private let analytics: Analytics
    private let userDefaults: UserDefaults

    init(siteID: Int64,
         analytics: Analytics = ServiceLocator.analytics,
         userDefaults: UserDefaults = .standard) {
        self.siteID = siteID
        self.analytics = analytics
        self.userDefaults = userDefaults
    }

    /// Determines whether snapshot tracking is required.
    func needsTracking() -> Bool {
        let siteIDsWithSnapshotTracked: [Int64] = userDefaults[.siteIDsWithSnapshotTracked] as? [Int64] ?? []
        return siteIDsWithSnapshotTracked.contains(siteID) == false
    }

    /// Tracks the store snapshot if it hasn't been tracked for the same store before.
    func trackIfNeeded(orderStatuses: [OrderStatus],
                       numberOfProducts: Int64,
                       systemPlugins: [SystemPlugin]) {
        // In case some data are fetched async after the first `needsTracking` call, it's called again to ensure
        // that tracking is required.
        guard needsTracking() else {
            return
        }

        let numberOfOrders = Int64(orderStatuses.map { $0.total }.reduce(0, +))

        let otherProperties: [String: Any] = [
            "orders_count": numberOfOrders,
            "products_count": numberOfProducts
        ]
        let paymentGatewaySnapshot = PaymentGatewaySnapshot(plugins: systemPlugins)
        let properties: [String: Any] = PaymentGatewaySnapshot.Plugin.allCases.reduce(otherProperties) { partialResult, plugin in
            var newResult = partialResult
            newResult[plugin.eventPropertyName] = paymentGatewaySnapshot.status(of: plugin).rawValue
            return newResult
        }
        analytics.track(.applicationSiteSnapshot, withProperties: properties)

        addSiteIDToUserDefaults()
    }
}

private extension SiteSnapshotTracker {
    func addSiteIDToUserDefaults() {
        var siteIDs = userDefaults[.siteIDsWithSnapshotTracked] as? [Int64] ?? []
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
        case payPal = "woocommerce-paypal-payments"

        var eventPropertyName: String {
            rawValue.replacingOccurrences(of: "-", with: "_")
        }
    }

    private let plugins: [SystemPlugin]

    init(plugins: [SystemPlugin]) {
        self.plugins = plugins
    }

    func status(of plugin: Plugin) -> Status {
        guard let systemPlugin = plugins.first(where: { $0.fileNameWithoutExtension == plugin.rawValue }) else {
            return .notInstalled
        }
        return systemPlugin.active ? .active: .installed
    }
}
