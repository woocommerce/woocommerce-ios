import Foundation
import WooFoundation


// MARK: - StorageType DataModel Specific Extensions
//
public extension StorageType {

    /// Retrieves the Stored Account.
    ///
    func loadAccount(userID: Int64) -> Account? {
        let predicate = \Account.userID == userID
        return firstObject(ofType: Account.self, matching: predicate)
    }

    /// Retrieves the Stores AccountSettings.
    ///
    func loadAccountSettings(userID: Int64) -> AccountSettings? {
        let predicate = \AccountSettings.userID == userID
        return firstObject(ofType: AccountSettings.self, matching: predicate)
    }

    /// Retrieves the Stored Site.
    ///
    func loadSite(siteID: Int64) -> Site? {
        let predicate = \Site.siteID == siteID
        return firstObject(ofType: Site.self, matching: predicate)
    }

    /// Retrieves all stored sites.
    ///
    func loadAllSites() -> [Site] {
        allObjects(ofType: Site.self, matching: nil, sortedBy: nil)
    }

    // MARK: - Orders

    /// Retrieves the Stored Order.
    ///
    func loadOrder(siteID: Int64, orderID: Int64) -> Order? {
        let predicate = \Order.orderID == orderID && \Order.siteID == siteID
        return firstObject(ofType: Order.self, matching: predicate)
    }

    /// Retrieves the Stored Order Lookup.
    ///
    func loadOrderSearchResults(keyword: String) -> OrderSearchResults? {
        let predicate = \OrderSearchResults.keyword == keyword
        return firstObject(ofType: OrderSearchResults.self, matching: predicate)
    }

    /// Retrieves the Stored Order Item.
    ///
    func loadOrderItem(siteID: Int64, orderID: Int64, itemID: Int64) -> OrderItem? {
        let predicate = \OrderItem.order.siteID == siteID && \OrderItem.order.orderID == orderID && \OrderItem.itemID == itemID
        return firstObject(ofType: OrderItem.self, matching: predicate)
    }

    /// Retrieves the Stored Order Item Tax.
    ///
    func loadOrderItemTax(itemID: Int64, taxID: Int64) -> OrderItemTax? {
        let predicate = \OrderItemTax.item?.itemID == itemID && \OrderItemTax.taxID == taxID
        return firstObject(ofType: OrderItemTax.self, matching: predicate)
    }

    /// Retrieves the Stored Order Coupon.
    ///
    func loadOrderCoupon(siteID: Int64, couponID: Int64) -> OrderCoupon? {
        let predicate = \OrderCoupon.order.siteID == siteID && \OrderCoupon.couponID == couponID
        return firstObject(ofType: OrderCoupon.self, matching: predicate)
    }

    /// Retrieves the Stored Order Fee.
    ///
    func loadOrderFeeLine(siteID: Int64, feeID: Int64) -> OrderFeeLine? {
        let predicate = \OrderFeeLine.order.siteID == siteID && \OrderFeeLine.feeID == feeID
        return firstObject(ofType: OrderFeeLine.self, matching: predicate)
    }

    /// Retrieves the Stored Order Refund Condensed.
    ///
    func loadOrderRefundCondensed(siteID: Int64, refundID: Int64) -> OrderRefundCondensed? {
        let predicate = \OrderRefundCondensed.order?.siteID == siteID && \OrderRefundCondensed.refundID == refundID
        return firstObject(ofType: OrderRefundCondensed.self, matching: predicate)
    }

    /// Retrieves the Stored Order Shipping Line.
    ///
    func loadOrderShippingLine(siteID: Int64, shippingID: Int64) -> ShippingLine? {
        let predicate = \ShippingLine.order?.siteID == siteID && \ShippingLine.shippingID == shippingID
        return firstObject(ofType: ShippingLine.self, matching: predicate)
    }

    /// Retrieves the Stored Order Shipping Line Tax.
    ///
    func loadShippingLineTax(shippingID: Int64, taxID: Int64) -> ShippingLineTax? {
        let predicate = \ShippingLineTax.shipping?.shippingID == shippingID && \ShippingLineTax.taxID == taxID
        return firstObject(ofType: ShippingLineTax.self, matching: predicate)
    }

    /// Retrieves the Stored Order Note.
    ///
    func loadOrderNote(noteID: Int64) -> OrderNote? {
        let predicate = \OrderNote.noteID == noteID
        return firstObject(ofType: OrderNote.self, matching: predicate)
    }

    /// Retrieves the Stored Order Tax Lines.
    ///
    func loadOrderTaxLine(siteID: Int64, taxID: Int64) -> OrderTaxLine? {
        let predicate = \OrderTaxLine.order.siteID == siteID && \OrderTaxLine.taxID == taxID
        return firstObject(ofType: OrderTaxLine.self, matching: predicate)
    }

    // MARK: - Stats

    /// Retrieves the Stored TopEarnerStats.
    ///
    func loadTopEarnerStats(date: String, granularity: String) -> TopEarnerStats? {
        let predicate = \TopEarnerStats.date =~ date && \TopEarnerStats.granularity =~ granularity
        return firstObject(ofType: TopEarnerStats.self, matching: predicate)
    }

    /// Retrieves the Stored SiteVisitStats for stats v4.
    ///
    func loadSiteVisitStats(granularity: String, timeRange: String) -> SiteVisitStats? {
        let predicate = \SiteVisitStats.granularity =~ granularity && \SiteVisitStats.timeRange == timeRange
        return firstObject(ofType: SiteVisitStats.self, matching: predicate)
    }

    /// Retrieves the Stored OrderStats for V4 API.
    ///
    func loadOrderStatsV4(siteID: Int64, timeRange: String) -> OrderStatsV4? {
        let predicate = \OrderStatsV4.siteID == siteID && \OrderStatsV4.timeRange =~ timeRange
        return firstObject(ofType: OrderStatsV4.self, matching: predicate)
    }

    /// Retrieves the Stored OrderStatsV4interval.
    ///
    func loadOrderStatsInterval(interval: String, orderStats: OrderStatsV4) -> OrderStatsV4Interval? {
        let predicate = \OrderStatsV4Interval.interval =~ interval && \OrderStatsV4Interval.stats == orderStats
        return firstObject(ofType: OrderStatsV4Interval.self, matching: predicate)
    }

    /// Retrieves the Stored SiteSummaryStats.
    ///
    func loadSiteSummaryStats(date: String, period: String) -> SiteSummaryStats? {
        let predicate = \SiteSummaryStats.date =~ date && \SiteSummaryStats.period =~ period
        return firstObject(ofType: SiteSummaryStats.self, matching: predicate)
    }

    // MARK: - Order Statuses

    /// Retrieves all of the Stores OrderStatuses for the provided siteID.
    ///
    func loadOrderStatuses(siteID: Int64) -> [OrderStatus]? {
        let predicate = \OrderStatus.siteID == siteID
        let descriptor = NSSortDescriptor(keyPath: \OrderStatus.name, ascending: false)
        return allObjects(ofType: OrderStatus.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Retrieves the Stored OrderStatus
    ///
    func loadOrderStatus(siteID: Int64, slug: String) -> OrderStatus? {
        let predicate = \OrderStatus.siteID == siteID && \OrderStatus.slug =~ slug
        return firstObject(ofType: OrderStatus.self, matching: predicate)
    }

    // MARK: - Site Settings

    /// Retrieves **all** of the stored SiteSettings for the provided siteID.
    ///
    func loadAllSiteSettings(siteID: Int64) -> [SiteSetting]? {
        let predicate = \SiteSetting.siteID == siteID
        let descriptor = NSSortDescriptor(keyPath: \SiteSetting.settingID, ascending: false)
        return allObjects(ofType: SiteSetting.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Retrieves stored SiteSettings for the provided siteID and settingGroupKey.
    ///
    func loadSiteSettings(siteID: Int64, settingGroupKey: String) -> [SiteSetting]? {
        let predicate = \SiteSetting.siteID == siteID && \SiteSetting.settingGroupKey =~ settingGroupKey
        let descriptor = NSSortDescriptor(keyPath: \SiteSetting.settingID, ascending: false)
        return allObjects(ofType: SiteSetting.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Retrieves the Stored SiteSetting.
    ///
    func loadSiteSetting(siteID: Int64, settingID: String) -> SiteSetting? {
        let predicate = \SiteSetting.siteID == siteID && \SiteSetting.settingID =~ settingID
        return firstObject(ofType: SiteSetting.self, matching: predicate)
    }

    // MARK: - Notifications

    /// Retrieves the Notification.
    ///
    func loadNotification(noteID: Int64) -> Note? {
        let predicate = \Note.noteID == noteID
        return firstObject(ofType: Note.self, matching: predicate)
    }

    /// Retrieves the Notification.
    ///
    func loadNotification(noteID: Int64, noteHash: Int) -> Note? {
        let predicate = \Note.noteID == noteID && \Note.noteHash == (Int64)(noteHash)
        return firstObject(ofType: Note.self, matching: predicate)
    }

    // MARK: - Shipment Tracking

    /// Retrieves a specific stored ShipmentTracking entity.
    ///
    func loadShipmentTracking(siteID: Int64, orderID: Int64, trackingID: String) -> ShipmentTracking? {
        let predicate = \ShipmentTracking.siteID == siteID && \ShipmentTracking.orderID == orderID && \ShipmentTracking.trackingID =~ trackingID
        return firstObject(ofType: ShipmentTracking.self, matching: predicate)
    }

    /// Retrieves all of the stored ShipmentTracking entities for the provided siteID and orderID.
    ///
    func loadShipmentTrackingList(siteID: Int64, orderID: Int64) -> [ShipmentTracking]? {
        let predicate = \ShipmentTracking.siteID == siteID && \ShipmentTracking.orderID == orderID
        let descriptor = NSSortDescriptor(keyPath: \ShipmentTracking.orderID, ascending: false)
        return allObjects(ofType: ShipmentTracking.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Retrieves a specific stored ShipmentTrackingProviderGroup
    ///
    func loadShipmentTrackingProviderGroup(siteID: Int64, providerGroupName: String) -> ShipmentTrackingProviderGroup? {
        let predicate = \ShipmentTrackingProviderGroup.siteID == siteID && \ShipmentTrackingProviderGroup.name =~ providerGroupName
        return firstObject(ofType: ShipmentTrackingProviderGroup.self, matching: predicate)
    }

    /// Retrieves all of the stored ShipmentTrackingProviderGroup entities for the provided siteID.
    ///
    func loadShipmentTrackingProviderGroupList(siteID: Int64) -> [ShipmentTrackingProviderGroup]? {
        let predicate = \ShipmentTrackingProviderGroup.siteID == siteID
        let descriptor = NSSortDescriptor(keyPath: \ShipmentTrackingProviderGroup.name, ascending: true)
        return allObjects(ofType: ShipmentTrackingProviderGroup.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Retrieves all of the stored ShipmentTrackingProvider entities for the provided siteID.
    ///
    func loadShipmentTrackingProviderList(siteID: Int64) -> [ShipmentTrackingProvider]? {
        let predicate = \ShipmentTrackingProvider.siteID == siteID
        let descriptor = NSSortDescriptor(keyPath: \ShipmentTrackingProvider.name, ascending: true)
        return allObjects(ofType: ShipmentTrackingProvider.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Retrieves a stored ShipmentTrackingProvider for the provided siteID.
    ///
    func loadShipmentTrackingProvider(siteID: Int64, name: String) -> ShipmentTrackingProvider? {
        let predicate = \ShipmentTrackingProvider.siteID == siteID && \ShipmentTrackingProvider.name =~ name
        return firstObject(ofType: ShipmentTrackingProvider.self, matching: predicate)
    }

    // MARK: - Products

    /// Retrieves all of the stored Products for the provided siteID.
    ///
    func loadProducts(siteID: Int64) -> [Product]? {
        let predicate = \Product.siteID == siteID
        let descriptor = NSSortDescriptor(keyPath: \Product.productID, ascending: false)
        return allObjects(ofType: Product.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Retrieves all of the stored Products matching the provided array products ids from the provided SiteID
    ///
    func loadProducts(siteID: Int64, productsIDs: [Int64]) -> [Product] {
        let predicate = \Product.siteID == siteID && \Product.productID === productsIDs
        return allObjects(ofType: Product.self, matching: predicate, sortedBy: nil)
    }

    /// Retrieves a stored Product for the provided siteID.
    ///
    func loadProduct(siteID: Int64, productID: Int64) -> Product? {
        let predicate = \Product.siteID == siteID && \Product.productID == productID
        return firstObject(ofType: Product.self, matching: predicate)
    }

    /// Retrieves the Stored Product Attribute.
    ///
    /// Note: WC attribute ID's often have an ID of `0`, so we need to also look them up by name 😏
    ///
    func loadProductAttribute(siteID: Int64, productID: Int64, attributeID: Int64, name: String) -> ProductAttribute? {
        let predicate = \ProductAttribute.product?.siteID == siteID && \ProductAttribute.product?.productID =~ productID
            && \ProductAttribute.attributeID == attributeID && \ProductAttribute.name == name
        return firstObject(ofType: ProductAttribute.self, matching: predicate)
    }

    /// Retrieves the Stored Product Attribute by ID.
    ///
    /// Note: this method is useful to fetch global attributes, which always have a non-zero ID.
    ///
    func loadProductAttribute(siteID: Int64, attributeID: Int64) -> ProductAttribute? {
        let predicate = \ProductAttribute.siteID == siteID && \ProductAttribute.attributeID == attributeID
        return firstObject(ofType: ProductAttribute.self, matching: predicate)
    }

    /// Retrieves the Stored Product Attribute Term by, attribute and term ID.
    ///
    func loadProductAttributeTerm(siteID: Int64, termID: Int64, attributeID: Int64) -> ProductAttributeTerm? {
        let predicate = \ProductAttributeTerm.siteID == siteID && \ProductAttributeTerm.termID == termID
            && \ProductAttributeTerm.attribute?.attributeID == attributeID
        return firstObject(ofType: ProductAttributeTerm.self, matching: predicate)
    }

    /// Retrieves the all of the stored Product Attributes for a `siteID`.
    ///
    func loadProductAttributes(siteID: Int64) -> [ProductAttribute] {
        let predicate = \ProductAttribute.siteID == siteID
        return allObjects(ofType: ProductAttribute.self, matching: predicate, sortedBy: nil)
    }

    /// Retrieves the Stored Product Default Attribute.
    ///
    /// Note: WC default attribute ID's often have an ID of `0`, so we need to also look them up by name 😏
    ///
    func loadProductDefaultAttribute(siteID: Int64, productID: Int64, defaultAttributeID: Int64, name: String) -> ProductDefaultAttribute? {
        let predicate = \ProductDefaultAttribute.product?.siteID == siteID && \ProductDefaultAttribute.product?.productID =~ productID
            && \ProductDefaultAttribute.attributeID == defaultAttributeID && \ProductDefaultAttribute.name == name
        return firstObject(ofType: ProductDefaultAttribute.self, matching: predicate)
    }

    /// Retrieves the Stored Product Image.
    ///
    func loadProductImage(siteID: Int64, productID: Int64, imageID: Int64) -> ProductImage? {
        let predicate = \ProductImage.product?.siteID == siteID && \ProductImage.product?.productID == productID && \ProductImage.imageID == imageID
        return firstObject(ofType: ProductImage.self, matching: predicate)
    }

    /// Retrieves the all of the stored Product Categories for a `siteID`.
    ///
    func loadProductCategories(siteID: Int64) -> [ProductCategory] {
        let predicate = \ProductCategory.siteID == siteID
        return allObjects(ofType: ProductCategory.self, matching: predicate, sortedBy: nil)
    }

    /// Retrieves the Stored Product Category.
    ///
    func loadProductCategory(siteID: Int64, categoryID: Int64) -> ProductCategory? {
        let predicate = \ProductCategory.siteID == siteID && \ProductCategory.categoryID == categoryID
        return firstObject(ofType: ProductCategory.self, matching: predicate)
    }

    /// Retrieves the Stored ProductSearchResults Lookup.
    ///
    func loadProductSearchResults(keyword: String, filterKey: String) -> ProductSearchResults? {
        let predicate = \ProductSearchResults.keyword == keyword && \ProductSearchResults.filterKey == filterKey
        return firstObject(ofType: ProductSearchResults.self, matching: predicate)
    }

    /// Retrieves the all of the stored Product Tags for a `siteID`.
    ///
    func loadProductTags(siteID: Int64) -> [ProductTag] {
        let predicate = \ProductTag.siteID == siteID
        return allObjects(ofType: ProductTag.self, matching: predicate, sortedBy: nil)
    }

    /// Retrieves the Stored Product Tag.
    ///
    func loadProductTag(siteID: Int64, tagID: Int64) -> ProductTag? {
        let predicate = \ProductTag.siteID == siteID && \ProductTag.tagID == tagID
        return firstObject(ofType: ProductTag.self, matching: predicate)
    }

    /// Retrieves all of the stored ProductReviews for the provided siteID. Sorted by dateCreated, descending
    ///
    func loadProductReviews(siteID: Int64) -> [ProductReview]? {
        let predicate = \ProductReview.siteID == siteID
        let descriptor = NSSortDescriptor(keyPath: \ProductReview.dateCreated, ascending: false)
        return allObjects(ofType: ProductReview.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Retrieves a stored ProductReview for the provided siteID and reviewID.
    ///
    func loadProductReview(siteID: Int64, reviewID: Int64) -> ProductReview? {
        let predicate = \ProductReview.siteID == siteID && \ProductReview.reviewID == reviewID
        return firstObject(ofType: ProductReview.self, matching: predicate)
    }

    /// Retrieves all of the stored ProductShippingClass's for the provided siteID.
    /// Sorted by name, ascending
    ///
    func loadProductShippingClasses(siteID: Int64) -> [ProductShippingClass]? {
        let predicate = \ProductShippingClass.siteID == siteID
        let descriptor = NSSortDescriptor(keyPath: \ProductShippingClass.name, ascending: true)
        return allObjects(ofType: ProductShippingClass.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Retrieves all of the stored ProductShippingClass's for the provided siteID.
    /// Sorted by name, ascending
    ///
    func loadProductShippingClass(siteID: Int64, remoteID: Int64) -> ProductShippingClass? {
        let predicate = \ProductShippingClass.siteID == siteID && \ProductShippingClass.shippingClassID == remoteID
        return firstObject(ofType: ProductShippingClass.self, matching: predicate)
    }

    /// Retrieves all of the stored ProductVariation's for the provided siteID and productID.
    /// Sorted by dateCreated, descending
    ///
    func loadProductVariations(siteID: Int64, productID: Int64) -> [ProductVariation]? {
        let predicate = \ProductVariation.siteID == siteID && \ProductVariation.productID == productID
        let descriptor = NSSortDescriptor(keyPath: \ProductVariation.dateCreated, ascending: false)
        return allObjects(ofType: ProductVariation.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Retrieves a stored ProductVariation for the provided siteID and productVariationID.
    ///
    func loadProductVariation(siteID: Int64, productVariationID: Int64) -> ProductVariation? {
        let predicate = \ProductVariation.siteID == siteID && \ProductVariation.productVariationID == productVariationID
        return firstObject(ofType: ProductVariation.self, matching: predicate)
    }

    /// Retrieves a stored TaxClass for the provided tax slug.
    ///
    func loadTaxClass(slug: String?) -> TaxClass? {
        guard let slug = slug else {
            return nil
        }

        let predicate = \TaxClass.slug == slug
        return firstObject(ofType: TaxClass.self, matching: predicate)
    }

    /// Retrieves all of the stored TaxClasses
    ///
    func loadTaxClasses() -> [TaxClass]? {
        let predicate = NSPredicate()
        return allObjects(ofType: TaxClass.self, matching: predicate, sortedBy: nil)
    }

    /// Returns a single TaxRate given a `siteID` and `id`
    ///
    func loadTaxRate(siteID: Int64, taxRateID: Int64) -> TaxRate? {
        let predicate = \TaxRate.siteID == siteID && \TaxRate.id == taxRateID
        return firstObject(ofType: TaxRate.self, matching: predicate)
    }

    /// Retrieves all of the stored TaxRates
    ///
    func loadTaxRates(siteID: Int64) -> [TaxRate] {
        let predicate = \TaxRate.siteID == siteID
        return allObjects(ofType: TaxRate.self, matching: predicate, sortedBy: nil)
    }

    // MARK: - Refunds

    /// Retrieves all of the stored Refund entities for the provided siteID and orderID.
    ///
    func loadRefunds(siteID: Int64, orderID: Int64) -> [Refund] {
        let predicate = \Refund.siteID == siteID && \Refund.orderID == orderID
        let descriptor = NSSortDescriptor(keyPath: \Refund.dateCreated, ascending: false)
        return allObjects(ofType: Refund.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Retrieves a stored Refund for the provided siteID, orderID, and refundID.
    ///
    func loadRefund(siteID: Int64, orderID: Int64, refundID: Int64) -> Refund? {
        let predicate = \Refund.siteID == siteID && \Refund.orderID == orderID && \Refund.refundID == refundID
        return firstObject(ofType: Refund.self, matching: predicate)
    }

    /// Retrieves the Stored OrderItemRefund.
    ///
    func loadRefundItem(siteID: Int64, refundID: Int64, itemID: Int64) -> OrderItemRefund? {
        let predicate = \OrderItemRefund.refund?.siteID == siteID && \OrderItemRefund.refund?.refundID == refundID && \OrderItemRefund.itemID == itemID
        return firstObject(ofType: OrderItemRefund.self, matching: predicate)
    }

    /// Retrieves the Stored Refund Shipping Line.
    ///
    func loadRefundShippingLine(siteID: Int64, shippingID: Int64) -> ShippingLine? {
        let predicate = \ShippingLine.refund?.siteID == siteID && \ShippingLine.shippingID == shippingID
        return firstObject(ofType: ShippingLine.self, matching: predicate)
    }

    /// Retrieves the Stored OrderItemTaxRefund.
    ///
    func loadRefundItemTax(itemID: Int64, taxID: Int64) -> OrderItemTaxRefund? {
        let predicate = \OrderItemTaxRefund.item?.itemID == itemID && \OrderItemTaxRefund.taxID == taxID
        return firstObject(ofType: OrderItemTaxRefund.self, matching: predicate)
    }

    // MARK: - Payment Gateways

    /// Returns all stored payment gateways for a site.
    ///
    func loadAllPaymentGateways(siteID: Int64) -> [PaymentGateway] {
        let predicate = \PaymentGateway.siteID == siteID
        return allObjects(ofType: PaymentGateway.self, matching: predicate, sortedBy: nil)
    }

    /// Returns a single payment gateway given a `siteID` and a `gatewayID`
    ///
    func loadPaymentGateway(siteID: Int64, gatewayID: String) -> PaymentGateway? {
        let predicate = \PaymentGateway.siteID == siteID && \PaymentGateway.gatewayID == gatewayID
        return firstObject(ofType: PaymentGateway.self, matching: predicate)
    }

    // MARK: - Data

    /// Returns all the countries stored.
    ///
    func loadCountries() -> [Country] {
        let descriptor = NSSortDescriptor(keyPath: \Country.name, ascending: true)
        return allObjects(ofType: Country.self, matching: nil, sortedBy: [descriptor])
    }

    // MARK: - Shipping Labels

    /// Returns all stored shipping labels for a site and order.
    ///
    func loadAllShippingLabels(siteID: Int64, orderID: Int64) -> [ShippingLabel] {
        let predicate = \ShippingLabel.siteID == siteID && \ShippingLabel.orderID == orderID
        return allObjects(ofType: ShippingLabel.self, matching: predicate, sortedBy: nil)
    }

    /// Returns a single shipping label given a `siteID`, `orderID`, and `shippingLabelID`
    ///
    func loadShippingLabel(siteID: Int64, orderID: Int64, shippingLabelID: Int64) -> ShippingLabel? {
        let predicate = \ShippingLabel.siteID == siteID && \ShippingLabel.orderID == orderID && \ShippingLabel.shippingLabelID == shippingLabelID
        return firstObject(ofType: ShippingLabel.self, matching: predicate)
    }

    /// Returns a single shipping label settings given a `siteID` and `orderID`
    ///
    func loadShippingLabelSettings(siteID: Int64, orderID: Int64) -> ShippingLabelSettings? {
        let predicate = \ShippingLabelSettings.siteID == siteID && \ShippingLabelSettings.orderID == orderID
        return firstObject(ofType: ShippingLabelSettings.self, matching: predicate)
    }

    // MARK: - BlazeCampaignListItem

    /// Returns a single BlazeCampaignListItem given a `siteID` and `campaignID`
    ///
    func loadBlazeCampaignListItem(siteID: Int64, campaignID: String) -> BlazeCampaignListItem? {
        let predicate = \BlazeCampaignListItem.siteID == siteID && \BlazeCampaignListItem.campaignID == campaignID
        return firstObject(ofType: BlazeCampaignListItem.self, matching: predicate)
    }

    /// Returns all stored BlazeCampaignListItem s for a site
    ///
    func loadAllBlazeCampaignListItems(siteID: Int64) -> [BlazeCampaignListItem] {
        let predicate = \BlazeCampaignListItem.siteID == siteID
        return allObjects(ofType: BlazeCampaignListItem.self, matching: predicate, sortedBy: nil)
    }

    // MARK: BlazeTargetDevice

    /// Returns all Blaze target devices with the given locale.
    ///
    func loadAllBlazeTargetDevices(locale: String) -> [BlazeTargetDevice] {
        let predicate = \BlazeTargetDevice.locale == locale
        return allObjects(ofType: BlazeTargetDevice.self, matching: predicate, sortedBy: nil)
    }

    // MARK: BlazeTargetLanguage

    /// Returns all Blaze target languages with the given locale.
    ///
    func loadAllBlazeTargetLanguages(locale: String) -> [BlazeTargetLanguage] {
        let predicate = \BlazeTargetLanguage.locale == locale
        return allObjects(ofType: BlazeTargetLanguage.self, matching: predicate, sortedBy: nil)
    }

    /// Returns all Blaze target topics with the given locale.
    ///
    func loadAllBlazeTargetTopics(locale: String) -> [BlazeTargetTopic] {
        let predicate = \BlazeTargetTopic.locale == locale
        return allObjects(ofType: BlazeTargetTopic.self, matching: predicate, sortedBy: nil)
    }

    /// Returns all Blaze campaign objectives with the given locale.
    ///
    func loadAllBlazeCampaignObjectives(locale: String) -> [BlazeCampaignObjective] {
        let predicate = \BlazeCampaignObjective.locale == locale
        return allObjects(ofType: BlazeCampaignObjective.self, matching: predicate, sortedBy: nil)
    }

    // MARK: - Coupons

    /// Returns a single Coupon given a `siteID` and `CouponID`
    ///
    func loadCoupon(siteID: Int64, couponID: Int64) -> Coupon? {
        let predicate = \Coupon.siteID == siteID && \Coupon.couponID == couponID
        return firstObject(ofType: Coupon.self, matching: predicate)
    }

    /// Returns all stored coupons for a site
    ///
    func loadAllCoupons(siteID: Int64) -> [Coupon] {
        let predicate = \Coupon.siteID == siteID
        return allObjects(ofType: Coupon.self, matching: predicate, sortedBy: nil)
    }

    /// Retrieves the Stored CouponSearchResult Lookup.
    ///
    func loadCouponSearchResult(keyword: String) -> CouponSearchResult? {
        let predicate = \CouponSearchResult.keyword == keyword
        return firstObject(ofType: CouponSearchResult.self, matching: predicate)
    }

    /// Returns all stored shipping label account settings for a site.
    ///
    func loadShippingLabelAccountSettings(siteID: Int64) -> ShippingLabelAccountSettings? {
        let predicate = \ShippingLabelAccountSettings.siteID == siteID
        return firstObject(ofType: ShippingLabelAccountSettings.self, matching: predicate)
    }

    /// Returns all stored add-on groups for a provided `siteID`.
    ///
    func loadAddOnGroups(siteID: Int64) -> [AddOnGroup] {
        let predicate = \AddOnGroup.siteID == siteID
        let descriptor = NSSortDescriptor(keyPath: \AddOnGroup.name, ascending: true)
        return allObjects(ofType: AddOnGroup.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Returns a single stored add-on group for a provided `siteID` and `groupID`.
    ///
    func loadAddOnGroup(siteID: Int64, groupID: Int64) -> AddOnGroup? {
        let predicate = \AddOnGroup.siteID == siteID && \AddOnGroup.groupID == groupID
        return firstObject(ofType: AddOnGroup.self, matching: predicate)
    }

    /// Returns all stored plugins for a provided `siteID`.
    ///
    func loadPlugins(siteID: Int64) -> [SitePlugin] {
        let predicate = \SitePlugin.siteID == siteID
        let descriptor = NSSortDescriptor(keyPath: \SitePlugin.name, ascending: true)
        return allObjects(ofType: SitePlugin.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Returns a plugin with a specified `siteID` and `name`
    ///
    func loadPlugin(siteID: Int64, name: String) -> SitePlugin? {
        let predicate = \SitePlugin.siteID == siteID && \SitePlugin.name == name
        return firstObject(ofType: SitePlugin.self, matching: predicate)
    }

    /// Returns all payment gateway accounts for a provided `siteID`
    ///
    func loadPaymentGatewayAccounts(siteID: Int64) -> [PaymentGatewayAccount] {
        let predicate = \PaymentGatewayAccount.siteID == siteID
        let descriptor = NSSortDescriptor(keyPath: \PaymentGatewayAccount.gatewayID, ascending: true)
        return allObjects(ofType: PaymentGatewayAccount.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Returns a payment gateway account with a specified `siteID` and `gatewayID`
    ///
    func loadPaymentGatewayAccount(siteID: Int64, gatewayID: String) -> PaymentGatewayAccount? {
        let predicate = \PaymentGatewayAccount.siteID == siteID && \PaymentGatewayAccount.gatewayID == gatewayID
        return firstObject(ofType: PaymentGatewayAccount.self, matching: predicate)
    }

    /// Returns a charge with a specified `siteID` and `chargeID`
    ///
    func loadWCPayCharge(siteID: Int64, chargeID: String) -> WCPayCharge? {
        let predicate = \WCPayCharge.siteID == siteID && \WCPayCharge.chargeID == chargeID
        return firstObject(ofType: WCPayCharge.self, matching: predicate)
    }

    // MARK: - Customers

    /// Returns a single Customer given a `siteID` and `customerID`
    ///
    func loadCustomer(siteID: Int64, customerID: Int64) -> Customer? {
        let predicate = \Customer.siteID == siteID && \Customer.customerID == customerID
        return firstObject(ofType: Customer.self, matching: predicate)
    }

    func loadAllCustomers(siteID: Int64) -> [Customer] {
        let predicate = \Customer.siteID == siteID
        return allObjects(ofType: Customer.self, matching: predicate, sortedBy: [])
    }

    /// Returns a CustomerSearchResult given a `siteID` and a `keyword`
    ///
    func loadCustomerSearchResult(siteID: Int64, keyword: String) -> CustomerSearchResult? {
        let predicate = \CustomerSearchResult.siteID == siteID && \CustomerSearchResult.keyword == keyword
        return firstObject(ofType: CustomerSearchResult.self, matching: predicate)
    }

    // MARK: - WCAnalytics Customers

    /// Returns a single WCAnalyticsCustomer given a `siteID` and `customerID`
    ///
    func loadWCAnalyticsCustomer(siteID: Int64, customerID: Int64) -> WCAnalyticsCustomer? {
        let predicate = \WCAnalyticsCustomer.siteID == siteID && \WCAnalyticsCustomer.customerID == customerID
        return firstObject(ofType: WCAnalyticsCustomer.self, matching: predicate)
    }

    func loadAllWCAnalyticsCustomers(siteID: Int64) -> [WCAnalyticsCustomer] {
        let predicate = \WCAnalyticsCustomer.siteID == siteID
        return allObjects(ofType: WCAnalyticsCustomer.self, matching: predicate, sortedBy: [])
    }

    /// Returns a WCAnalyticsCustomerSearchResult given a `siteID` and a `keyword`
    ///
    func loadWCAnalyticsCustomerSearchResult(siteID: Int64, keyword: String) -> WCAnalyticsCustomerSearchResult? {
        let predicate = \WCAnalyticsCustomerSearchResult.siteID == siteID && \WCAnalyticsCustomerSearchResult.keyword == keyword
        return firstObject(ofType: WCAnalyticsCustomerSearchResult.self, matching: predicate)
    }

    // MARK: - System plugins

    /// Returns all stored system plugins for a provided `siteID`.
    ///
    func loadSystemPlugins(siteID: Int64) -> [SystemPlugin] {
        let predicate = \SystemPlugin.siteID == siteID
        let descriptor = NSSortDescriptor(keyPath: \SystemPlugin.name, ascending: true)
        return allObjects(ofType: SystemPlugin.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Returns a system plugin with a specified `siteID` and `name`
    ///
    func loadSystemPlugin(siteID: Int64, name: String) -> SystemPlugin? {
        let predicate = \SystemPlugin.siteID == siteID && \SystemPlugin.name == name
        return firstObject(ofType: SystemPlugin.self, matching: predicate)
    }

    /// Returns a system plugin with a specified `siteID` and `path`.
    ///
    func loadSystemPlugin(siteID: Int64, path: String) -> SystemPlugin? {
        let predicate = \SystemPlugin.siteID == siteID && \SystemPlugin.plugin == path
        return firstObject(ofType: SystemPlugin.self, matching: predicate)
    }

    // MARK: - Inbox Notes

    /// Returns a single Inbox Note given a `siteID` and `id`
    ///
    func loadInboxNote(siteID: Int64, id: Int64) -> InboxNote? {
        let predicate = \InboxNote.siteID == siteID && \InboxNote.id == id
        return firstObject(ofType: InboxNote.self, matching: predicate)
    }

    /// Returns all stored Inbox Notes for a provided `siteID`.
    ///
    func loadAllInboxNotes(siteID: Int64) -> [InboxNote] {
        let predicate = \InboxNote.siteID == siteID
        let descriptor = NSSortDescriptor(keyPath: \InboxNote.dateCreated, ascending: false)
        return allObjects(ofType: InboxNote.self, matching: predicate, sortedBy: [descriptor])
    }

    /// Retrieves the Stored Order Attribution Info.
    ///
    func loadOrderAttributionInfo(siteID: Int64, orderID: Int64) -> OrderAttributionInfo? {
        let predicate = \OrderAttributionInfo.order?.siteID == siteID && \OrderAttributionInfo.order?.orderID == orderID
        return firstObject(ofType: OrderAttributionInfo.self, matching: predicate)
    }

    // MARK: - Meta Data

    /// Retrieves the Stored Metadata for Order.
    ///
    func loadOrderMetaData(siteID: Int64, orderID: Int64, metadataID: Int64) -> MetaData? {
        let predicate = \MetaData.order?.siteID == siteID && \MetaData.order?.orderID == orderID && \MetaData.metadataID == metadataID
        return firstObject(ofType: MetaData.self, matching: predicate)
    }

    /// Retrieves the Stored Metadata for a Product.
    ///
    func loadProductMetaData(siteID: Int64, productID: Int64, metadataID: Int64) -> MetaData? {
        let predicate = \MetaData.product?.siteID == siteID && \MetaData.product?.productID == productID && \MetaData.metadataID == metadataID
        return firstObject(ofType: MetaData.self, matching: predicate)
    }

}
