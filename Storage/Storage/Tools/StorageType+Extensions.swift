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
    public func loadTopEarnerStats(period: String, granularity: String, limit: String) -> TopEarnerStats? {
        let predicate = NSPredicate(format: "period == %@ AND granularity == %@ AND limit == %@", period, granularity, limit)
        return firstObject(ofType: TopEarnerStats.self, matching: predicate)
    }

    /// Retrieves the Stored TopEarnerStats Item.
    ///
    public func loadTopEarnerStatsItem(productID: Int) -> TopEarnerStatsItem? {
        let predicate = NSPredicate(format: "productID = %ld", productID)
        return firstObject(ofType: TopEarnerStatsItem.self, matching: predicate)
    }
}
