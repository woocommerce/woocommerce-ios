import Foundation


// MARK: - StorageType DataModel Specific Extensions
//
public extension StorageType {

    /// Retrieves the Stored Account.
    ///
    func loadAccount(userId: Int) -> Account? {
        let predicate = NSPredicate(format: "userID = %ld", userId)
        return firstObject(ofType: Account.self, matching: predicate)
    }

    /// Retrieves the Stores AccountSettings.
    ///
    func loadAccountSettings(userId: Int) -> AccountSettings? {
        let predicate = NSPredicate(format: "userID = %ld", userId)
        return firstObject(ofType: AccountSettings.self, matching: predicate)
    }

    /// Retrieves the Stored Site.
    ///
    func loadSite(siteID: Int) -> Site? {
        let predicate = NSPredicate(format: "siteID = %ld", siteID)
        return firstObject(ofType: Site.self, matching: predicate)
    }

    /// Retrieves the Stored Order.
    ///
    func loadOrder(orderID: Int) -> Order? {
        let predicate = NSPredicate(format: "orderID = %ld", orderID)
        return firstObject(ofType: Order.self, matching: predicate)
    }

    /// Retrieves the Stored Order Lookup.
    ///
    func loadOrderSearchResults(keyword: String) -> OrderSearchResults? {
        let predicate = NSPredicate(format: "keyword = %@", keyword)
        return firstObject(ofType: OrderSearchResults.self, matching: predicate)
    }

    /// Retrieves the Stored Order Item.
    ///
    func loadOrderItem(itemID: Int) -> OrderItem? {
        let predicate = NSPredicate(format: "itemID = %ld", itemID)
        return firstObject(ofType: OrderItem.self, matching: predicate)
    }

    /// Retrieves the Stored Order Coupon.
    ///
    func loadOrderCoupon(couponID: Int) -> OrderCoupon? {
        let predicate = NSPredicate(format: "couponID = %ld", couponID)
        return firstObject(ofType: OrderCoupon.self, matching: predicate)
    }

    /// Retrieves the Stored Order Note.
    ///
    func loadOrderNote(noteID: Int) -> OrderNote? {
        let predicate = NSPredicate(format: "noteID = %ld", noteID)
        return firstObject(ofType: OrderNote.self, matching: predicate)
    }

    /// Retrieves the Stored OrderCount.
    ///
    func loadOrderCount(siteID: Int) -> OrderCount? {
        let predicate = NSPredicate(format: "siteID = %ld", siteID)
        return firstObject(ofType: OrderCount.self, matching: predicate)
    }

    /// Retrieves the Stored TopEarnerStats.
    ///
    func loadTopEarnerStats(date: String, granularity: String) -> TopEarnerStats? {
        let predicate = NSPredicate(format: "date ==[c] %@ AND granularity ==[c] %@", date, granularity)
        return firstObject(ofType: TopEarnerStats.self, matching: predicate)
    }

    /// Retrieves the Stored SiteVisitStats.
    ///
    func loadSiteVisitStats(granularity: String) -> SiteVisitStats? {
        let predicate = NSPredicate(format: "granularity ==[c] %@", granularity)
        return firstObject(ofType: SiteVisitStats.self, matching: predicate)
    }

    /// Retrieves the Stored SiteVisitStats for stats v4.
    ///
    func loadSiteVisitStats(granularity: String, date: String) -> SiteVisitStats? {
        let predicate = NSPredicate(format: "granularity ==[c] %@ AND date = %@", granularity, date)
        return firstObject(ofType: SiteVisitStats.self, matching: predicate)
    }

    /// Retrieves the Stored OrderStats.
    ///
    func loadOrderStats(granularity: String) -> OrderStats? {
        let predicate = NSPredicate(format: "granularity ==[c] %@", granularity)
        return firstObject(ofType: OrderStats.self, matching: predicate)
    }

    /// Retrieves the Stored OrderStatsItem.
    ///
    func loadOrderStatsItem(period: String) -> OrderStatsItem? {
        let predicate = NSPredicate(format: "period ==[c] %@", period)
        return firstObject(ofType: OrderStatsItem.self, matching: predicate)
    }

    /// Retrieves the Stored OrderStats for V4 API.
    ///
    func loadOrderStatsV4(siteID: Int, timeRange: String) -> OrderStatsV4? {
        let predicate = NSPredicate(format: "siteID = %ld AND timeRange ==[c] %@", siteID, timeRange)
        return firstObject(ofType: OrderStatsV4.self, matching: predicate)
    }

    /// Retrieves the Stored OrderStatsV4interval.
    ///
    func loadOrderStatsInterval(interval: String, orderStats: OrderStatsV4) -> OrderStatsV4Interval? {
        let predicate = NSPredicate(format: "interval ==[c] %@ AND stats = %@", interval, orderStats)
        return firstObject(ofType: OrderStatsV4Interval.self, matching: predicate)
    }

    /// Retrieves all of the Stores OrderStatuses for the provided siteID.
    ///
    func loadOrderStatuses(siteID: Int) -> [OrderStatus]? {
        let predicate = NSPredicate(format: "siteID = %ld", siteID)
        let descriptor = NSSortDescriptor(keyPath: \OrderStatus.name, ascending: false)
        return allObjects(ofType: OrderStatus.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Retrieves the Stored OrderStatus
    ///
    func loadOrderStatus(siteID: Int, slug: String) -> OrderStatus? {
        let predicate = NSPredicate(format: "siteID = %ld AND slug ==[c] %@", siteID, slug)
        return firstObject(ofType: OrderStatus.self, matching: predicate)
    }

    /// Retrieves **all** of the stored SiteSettings for the provided siteID.
    ///
    func loadAllSiteSettings(siteID: Int) -> [SiteSetting]? {
        let predicate = NSPredicate(format: "siteID = %ld", siteID)
        let descriptor = NSSortDescriptor(keyPath: \SiteSetting.settingID, ascending: false)
        return allObjects(ofType: SiteSetting.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Retrieves stored SiteSettings for the provided siteID and settingGroupKey.
    ///
    func loadSiteSettings(siteID: Int, settingGroupKey: String) -> [SiteSetting]? {
        let predicate = NSPredicate(format: "siteID = %ld AND settingGroupKey ==[c] %@", siteID, settingGroupKey)
        let descriptor = NSSortDescriptor(keyPath: \SiteSetting.settingID, ascending: false)
        return allObjects(ofType: SiteSetting.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Retrieves the Stored SiteSetting.
    ///
    func loadSiteSetting(siteID: Int, settingID: String) -> SiteSetting? {
        let predicate = NSPredicate(format: "siteID = %ld AND settingID ==[c] %@", siteID, settingID)
        return firstObject(ofType: SiteSetting.self, matching: predicate)
    }

    /// Retrieves the Notification.
    ///
    func loadNotification(noteID: Int64) -> Note? {
        let predicate = NSPredicate(format: "noteID = %ld", noteID)
        return firstObject(ofType: Note.self, matching: predicate)
    }

    /// Retrieves the Notification.
    ///
    func loadNotification(noteID: Int64, noteHash: Int) -> Note? {
        let predicate = NSPredicate(format: "noteID = %ld AND noteHash = %ld", noteID, noteHash)
        return firstObject(ofType: Note.self, matching: predicate)
    }

    /// Retrieves a specific stored ShipmentTracking entity.
    ///
    func loadShipmentTracking(siteID: Int, orderID: Int, trackingID: String) -> ShipmentTracking? {
        let predicate = NSPredicate(format: "siteID = %ld AND orderID = %ld AND trackingID ==[c] %@", siteID, orderID, trackingID)
        return firstObject(ofType: ShipmentTracking.self, matching: predicate)
    }

    /// Retrieves all of the stored ShipmentTracking entities for the provided siteID and orderID.
    ///
    func loadShipmentTrackingList(siteID: Int, orderID: Int) -> [ShipmentTracking]? {
        let predicate = NSPredicate(format: "siteID = %ld AND orderID = %ld", siteID, orderID)
        let descriptor = NSSortDescriptor(keyPath: \ShipmentTracking.orderID, ascending: false)
        return allObjects(ofType: ShipmentTracking.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Retrieves a specific stored ShipmentTrackingProviderGroup
    ///
    func loadShipmentTrackingProviderGroup(siteID: Int, providerGroupName: String) -> ShipmentTrackingProviderGroup? {
        let predicate = NSPredicate(format: "siteID = %ld AND name ==[c] %@", siteID, providerGroupName)
        return firstObject(ofType: ShipmentTrackingProviderGroup.self, matching: predicate)
    }

    /// Retrieves all of the stored ShipmentTrackingProviderGroup entities for the provided siteID.
    ///
    func loadShipmentTrackingProviderGroupList(siteID: Int) -> [ShipmentTrackingProviderGroup]? {
        let predicate = NSPredicate(format: "siteID = %ld", siteID)
        let descriptor = NSSortDescriptor(keyPath: \ShipmentTrackingProviderGroup.name, ascending: true)
        return allObjects(ofType: ShipmentTrackingProviderGroup.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Retrieves all of the stored ShipmentTrackingProvider entities for the provided siteID.
    ///
    func loadShipmentTrackingProviderList(siteID: Int) -> [ShipmentTrackingProvider]? {
        let predicate = NSPredicate(format: "siteID = %ld", siteID)
        let descriptor = NSSortDescriptor(keyPath: \ShipmentTrackingProvider.name, ascending: true)
        return allObjects(ofType: ShipmentTrackingProvider.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Retrieves a stored ShipmentTrackingProvider for the provided siteID.
    ///
    func loadShipmentTrackingProvider(siteID: Int, name: String) -> ShipmentTrackingProvider? {
        let predicate = NSPredicate(format: "siteID = %ld AND name ==[c] %@", siteID, name)
        return firstObject(ofType: ShipmentTrackingProvider.self, matching: predicate)
    }

    /// Retrieves all of the stored Products for the provided siteID.
    ///
    func loadProducts(siteID: Int) -> [Product]? {
        let predicate = NSPredicate(format: "siteID = %ld", siteID)
        let descriptor = NSSortDescriptor(keyPath: \Product.productID, ascending: false)
        return allObjects(ofType: Product.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Retrieves a stored Product for the provided siteID.
    ///
    func loadProduct(siteID: Int, productID: Int) -> Product? {
        let predicate = NSPredicate(format: "siteID = %ld AND productID = %ld", siteID, productID)
        return firstObject(ofType: Product.self, matching: predicate)
    }

    /// Retrieves the Stored Product Attribute.
    ///
    /// Note: WC attribute ID's often have an ID of `0`, so we need to also look them up by name 😏
    ///
    func loadProductAttribute(siteID: Int, productID: Int, attributeID: Int, name: String) -> ProductAttribute? {
        let predicate = NSPredicate(format: "product.siteID = %ld AND product.productID = %ld AND attributeID = %ld AND name ==[c] %@",
                                    siteID, productID, attributeID, name)
        return firstObject(ofType: ProductAttribute.self, matching: predicate)
    }

    /// Retrieves the Stored Product Default Attribute.
    ///
    /// Note: WC default attribute ID's often have an ID of `0`, so we need to also look them up by name 😏
    ///
    func loadProductDefaultAttribute(siteID: Int, productID: Int, defaultAttributeID: Int, name: String) -> ProductDefaultAttribute? {
        let predicate = NSPredicate(format: "product.siteID = %ld AND product.productID = %ld AND attributeID = %ld AND name ==[c] %@",
                                    siteID, productID, defaultAttributeID, name)
        return firstObject(ofType: ProductDefaultAttribute.self, matching: predicate)
    }

    /// Retrieves the Stored Product Image.
    ///
    func loadProductImage(siteID: Int, productID: Int, imageID: Int) -> ProductImage? {
        let predicate = NSPredicate(format: "product.siteID = %ld AND product.productID = %ld AND imageID = %ld", siteID, productID, imageID)
        return firstObject(ofType: ProductImage.self, matching: predicate)
    }

    /// Retrieves the Stored Product Category.
    ///
    func loadProductCategory(siteID: Int, productID: Int, categoryID: Int) -> ProductCategory? {
        let predicate = NSPredicate(format: "product.siteID = %ld AND product.productID = %ld AND categoryID = %ld", siteID, productID, categoryID)
        return firstObject(ofType: ProductCategory.self, matching: predicate)
    }

    /// Retrieves the Stored Product Tag.
    ///
    func loadProductTag(siteID: Int, productID: Int, tagID: Int) -> ProductTag? {
        let predicate = NSPredicate(format: "product.siteID = %ld AND product.productID = %ld AND tagID = %ld", siteID, productID, tagID)
        return firstObject(ofType: ProductTag.self, matching: predicate)
    }
}
