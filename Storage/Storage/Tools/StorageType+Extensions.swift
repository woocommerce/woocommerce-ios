import Foundation


// MARK: - StorageType DataModel Specific Extensions
//
public extension StorageType {

    /// Retrieves the Stored Account.
    ///
    public func loadAccount(userId: Int) -> Account? {
        let predicate = NSPredicate(format: "userID = %ld", userId)
        return firstObject(ofType: Account.self, matching: predicate)
    }

    /// Retrieves the Stored Site.
    ///
    public func loadSite(siteID: Int) -> Site? {
        let predicate = NSPredicate(format: "siteID = %ld", siteID)
        return firstObject(ofType: Site.self, matching: predicate)
    }

    /// Retrieves the Stored Order.
    ///
    public func loadOrder(orderID: Int) -> Order? {
        let predicate = NSPredicate(format: "orderID = %ld", orderID)
        return firstObject(ofType: Order.self, matching: predicate)
    }

    /// Retrieves the Stored Order Lookup.
    ///
    public func loadOrderSearchResults(keyword: String) -> OrderSearchResults? {
        let predicate = NSPredicate(format: "keyword = %@", keyword)
        return firstObject(ofType: OrderSearchResults.self, matching: predicate)
    }

    /// Retrieves the Stored Order Item.
    ///
    public func loadOrderItem(itemID: Int) -> OrderItem? {
        let predicate = NSPredicate(format: "itemID = %ld", itemID)
        return firstObject(ofType: OrderItem.self, matching: predicate)
    }

    /// Retrieves the Stored Order Coupon.
    ///
    public func loadOrderCoupon(couponID: Int) -> OrderCoupon? {
        let predicate = NSPredicate(format: "couponID = %ld", couponID)
        return firstObject(ofType: OrderCoupon.self, matching: predicate)
    }

    /// Retrieves the Stored Order Note.
    ///
    public func loadOrderNote(noteID: Int) -> OrderNote? {
        let predicate = NSPredicate(format: "noteID = %ld", noteID)
        return firstObject(ofType: OrderNote.self, matching: predicate)
    }

    /// Retrieves the Stored TopEarnerStats.
    ///
    public func loadTopEarnerStats(date: String, granularity: String) -> TopEarnerStats? {
        let predicate = NSPredicate(format: "date ==[c] %@ AND granularity ==[c] %@", date, granularity)
        return firstObject(ofType: TopEarnerStats.self, matching: predicate)
    }

    /// Retrieves the Stored SiteVisitStats.
    ///
    public func loadSiteVisitStats(granularity: String) -> SiteVisitStats? {
        let predicate = NSPredicate(format: "granularity ==[c] %@", granularity)
        return firstObject(ofType: SiteVisitStats.self, matching: predicate)
    }

    /// Retrieves the Stored OrderStats.
    ///
    public func loadOrderStats(granularity: String) -> OrderStats? {
        let predicate = NSPredicate(format: "granularity ==[c] %@", granularity)
        return firstObject(ofType: OrderStats.self, matching: predicate)
    }

    /// Retrieves the Stored OrderStatsItem.
    ///
    public func loadOrderStatsItem(period: String) -> OrderStatsItem? {
        let predicate = NSPredicate(format: "period ==[c] %@", period)
        return firstObject(ofType: OrderStatsItem.self, matching: predicate)
    }

    /// Retrieves all of the Stored SiteSettings for the provided siteID.
    ///
    public func loadSiteSettings(siteID: Int) -> [SiteSetting]? {
        let predicate = NSPredicate(format: "siteID = %ld", siteID)
        let descriptor = NSSortDescriptor(keyPath: \SiteSetting.settingID, ascending: false)
        return allObjects(ofType: SiteSetting.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Retrieves the Stored SiteSetting.
    ///
    public func loadSiteSetting(siteID: Int, settingID: String) -> SiteSetting? {
        let predicate = NSPredicate(format: "siteID = %ld AND settingID ==[c] %@", siteID, settingID)
        return firstObject(ofType: SiteSetting.self, matching: predicate)
    }

    /// Retrieves the Notification.
    ///
    public func loadNotification(noteID: Int64) -> Note? {
        let predicate = NSPredicate(format: "noteID = %ld", noteID)
        return firstObject(ofType: Note.self, matching: predicate)
    }

    /// Retrieves the Notification.
    ///
    public func loadNotification(noteID: Int64, noteHash: Int) -> Note? {
        let predicate = NSPredicate(format: "noteID = %ld AND noteHash = %ld", noteID, noteHash)
        return firstObject(ofType: Note.self, matching: predicate)
    }

    /// Retrieves a specific stored ShipmentTracking entity.
    ///
    public func loadShipmentTracking(siteID: Int, orderID: Int, trackingID: String) -> ShipmentTracking? {
        let predicate = NSPredicate(format: "siteID = %ld AND orderID = %ld AND trackingID ==[c] %@", siteID, orderID, trackingID)
        return firstObject(ofType: ShipmentTracking.self, matching: predicate)
    }

    /// Retrieves all of the stored ShipmentTracking entities for the provided siteID and orderID.
    ///
    public func loadShipmentTrackingList(siteID: Int, orderID: Int) -> [ShipmentTracking]? {
        let predicate = NSPredicate(format: "siteID = %ld AND orderID = %ld", siteID, orderID)
        let descriptor = NSSortDescriptor(keyPath: \ShipmentTracking.orderID, ascending: false)
        return allObjects(ofType: ShipmentTracking.self, matching: predicate, sortedBy: [descriptor])
    }
}
