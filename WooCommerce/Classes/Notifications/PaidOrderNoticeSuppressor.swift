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
    private let siteForID: (Int64) -> Site?
    private let suppressionInterval: TimeInterval = 5 * 60
    private var recentlyPaidOrders: [PaidOrderKey: Date] = [:]

    init(stores: StoresManager, currentDate: @escaping () -> Date, siteForID: @escaping (Int64) -> Site? = { _ in nil }) {
        self.stores = stores
        self.currentDate = currentDate
        self.siteForID = siteForID
    }

    mutating func recordPayment(for order: Order) {
        let now = currentDate()
        removeExpiredRecords(at: now)
        recentlyPaidOrders[key(siteID: order.siteID, orderID: order.orderID)] = now.addingTimeInterval(suppressionInterval)
    }

    mutating func shouldSuppress(_ notification: PushNotification) -> Bool {
        removeExpiredRecords(at: currentDate())
        guard notification.kind == .storeOrder,
              let orderID = notification.meta?.identifier(forKey: .order) else {
            return false
        }
        let siteID = notification.resolvedSiteID(stores: stores)
        if siteID == WooConstants.placeholderStoreID, !belongsToSelectedStore(notification) {
            return false
        }
        let key = key(siteID: siteID, orderID: Int64(orderID))
        return recentlyPaidOrders[key] != nil
    }

    private func belongsToSelectedStore(_ notification: PushNotification) -> Bool {
        guard notification.siteID > 0,
              let site = siteForID(notification.siteID),
              site.siteID == notification.siteID,
              let storeURL = stores.sessionManager.defaultSite?.url,
              !storeURL.isEmpty else {
            return false
        }
        return site.url == storeURL
    }

    private func key(siteID: Int64, orderID: Int64) -> PaidOrderKey {
        PaidOrderKey(siteID: siteID,
                     orderID: orderID,
                     storeURL: siteID == WooConstants.placeholderStoreID ? stores.sessionManager.defaultSite?.url : nil)
    }

    private mutating func removeExpiredRecords(at now: Date) {
        recentlyPaidOrders = recentlyPaidOrders.filter { $0.value > now }
    }
}
