import Foundation
import Yosemite

@MainActor
struct PaidOrderNoticeSuppressor {
    private struct PaidOrderKey: Hashable {
        let siteID: Int64
        let orderID: Int64
        let storeURL: String?
    }

    private let stores: StoresManager
    private let currentDate: () -> Date
    private let suppressionInterval: TimeInterval = 5 * 60
    private var recentlyPaidOrders: [PaidOrderKey: Date] = [:]

    init(stores: StoresManager, currentDate: @escaping () -> Date) {
        self.stores = stores
        self.currentDate = currentDate
    }

    mutating func recordPayment(for order: Order) {
        let now = currentDate()
        removeExpiredRecords(at: now)
        guard let key = key(siteID: order.siteID, orderID: order.orderID) else {
            return
        }
        recentlyPaidOrders[key] = now.addingTimeInterval(suppressionInterval)
    }

    mutating func shouldSuppress(_ notification: PushNotification) -> Bool {
        removeExpiredRecords(at: currentDate())
        guard notification.kind == .storeOrder,
              let orderID = notification.meta?.identifier(forKey: .order) else {
            return false
        }
        let siteID = notification.resolvedSiteID(stores: stores)
        guard let key = key(siteID: siteID, orderID: Int64(orderID)) else {
            return false
        }
        return recentlyPaidOrders[key] != nil
    }

    private func key(siteID: Int64, orderID: Int64) -> PaidOrderKey? {
        if siteID == WooConstants.placeholderStoreID {
            // Site-credential sessions use single-store routing, so the current store URL scopes the payment record.
            guard let storeURL = stores.sessionManager.defaultSite?.url, !storeURL.isEmpty else {
                return nil
            }
            return PaidOrderKey(siteID: siteID, orderID: orderID, storeURL: storeURL)
        }
        return PaidOrderKey(siteID: siteID, orderID: orderID, storeURL: nil)
    }

    private mutating func removeExpiredRecords(at now: Date) {
        recentlyPaidOrders = recentlyPaidOrders.filter { $0.value > now }
    }
}
