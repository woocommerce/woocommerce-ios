// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Yosemite
import Networking
import Hardware
import WooFoundation

// swiftlint:disable line_length

extension NetworkingCore.Account {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.Account {
        .init(
            userID: .fake(),
            displayName: .fake(),
            email: .fake(),
            username: .fake(),
            gravatarUrl: .fake()
        )
    }
}
extension NetworkingCore.Address {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.Address {
        .init(
            firstName: .fake(),
            lastName: .fake(),
            company: .fake(),
            address1: .fake(),
            address2: .fake(),
            city: .fake(),
            state: .fake(),
            postcode: .fake(),
            country: .fake(),
            phone: .fake(),
            email: .fake()
        )
    }
}
extension NetworkingCore.DotcomError {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.DotcomError {
        .empty()
    }
}
extension NetworkingCore.MetaContainer {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.MetaContainer {
        .init(
            payload: .fake()
        )
    }
}
extension NetworkingCore.MetaData {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.MetaData {
        .init(
            metadataID: .fake(),
            key: .fake(),
            value: .fake()
        )
    }
}
extension NetworkingCore.Note {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.Note {
        .init(
            noteID: .fake(),
            hash: .fake(),
            read: .fake(),
            icon: .fake(),
            noticon: .fake(),
            timestamp: .fake(),
            type: .fake(),
            subtype: .fake(),
            url: .fake(),
            title: .fake(),
            subject: .fake(),
            header: .fake(),
            body: .fake(),
            meta: .fake()
        )
    }
}
extension NetworkingCore.Note.Kind {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.Note.Kind {
        .automattcher
    }
}
extension NetworkingCore.NoteBlock {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.NoteBlock {
        .init(
            media: .fake(),
            ranges: .fake(),
            text: .fake(),
            actions: .fake(),
            meta: .fake(),
            type: .fake()
        )
    }
}
extension NetworkingCore.NoteMedia {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.NoteMedia {
        .init(
            type: .fake(),
            range: .fake(),
            url: .fake(),
            size: .fake()
        )
    }
}
extension NetworkingCore.NoteRange {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.NoteRange {
        .init(
            type: .fake(),
            range: .fake(),
            url: .fake(),
            identifier: .fake(),
            postID: .fake(),
            siteID: .fake(),
            value: .fake()
        )
    }
}
extension NetworkingCore.NoteRange.Kind {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.NoteRange.Kind {
        .user
    }
}
extension NetworkingCore.Order {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.Order {
        .init(
            siteID: .fake(),
            orderID: .fake(),
            parentID: .fake(),
            customerID: .fake(),
            orderKey: .fake(),
            isEditable: .fake(),
            needsPayment: .fake(),
            needsProcessing: .fake(),
            number: .fake(),
            status: .fake(),
            currency: .fake(),
            currencySymbol: .fake(),
            customerNote: .fake(),
            dateCreated: .fake(),
            dateModified: .fake(),
            datePaid: .fake(),
            discountTotal: .fake(),
            discountTax: .fake(),
            shippingTotal: .fake(),
            shippingTax: .fake(),
            total: .fake(),
            totalTax: .fake(),
            paymentMethodID: .fake(),
            paymentMethodTitle: .fake(),
            paymentURL: .fake(),
            chargeID: .fake(),
            paymentStatusMetadata: .fake(),
            fulfillmentStatus: .fake(),
            items: .fake(),
            billingAddress: .fake(),
            shippingAddress: .fake(),
            shippingLines: .fake(),
            coupons: .fake(),
            refunds: .fake(),
            fees: .fake(),
            taxes: .fake(),
            customFields: .fake(),
            renewalSubscriptionID: .fake(),
            appliedGiftCards: .fake(),
            attributionInfo: .fake(),
            shippingLabels: .fake(),
            fulfillments: .fake(),
            createdVia: .fake()
        )
    }
}
extension NetworkingCore.OrderAttributionInfo {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.OrderAttributionInfo {
        .init(
            sourceType: .fake(),
            campaign: .fake(),
            source: .fake(),
            medium: .fake(),
            deviceType: .fake(),
            sessionPageViews: .fake()
        )
    }
}
extension NetworkingCore.OrderCouponLine {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.OrderCouponLine {
        .init(
            couponID: .fake(),
            code: .fake(),
            discount: .fake(),
            discountTax: .fake()
        )
    }
}
extension NetworkingCore.OrderFeeLine {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.OrderFeeLine {
        .init(
            feeID: .fake(),
            name: .fake(),
            taxClass: .fake(),
            taxStatus: .fake(),
            total: .fake(),
            totalTax: .fake(),
            taxes: .fake(),
            attributes: .fake()
        )
    }
}
extension NetworkingCore.OrderFeeTaxStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.OrderFeeTaxStatus {
        .taxable
    }
}
extension NetworkingCore.OrderFulfillmentStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.OrderFulfillmentStatus {
        .fulfilled
    }
}
extension NetworkingCore.OrderGiftCard {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.OrderGiftCard {
        .init(
            giftCardID: .fake(),
            code: .fake(),
            amount: .fake()
        )
    }
}
extension NetworkingCore.OrderItem {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.OrderItem {
        .init(
            itemID: .fake(),
            name: .fake(),
            productID: .fake(),
            variationID: .fake(),
            quantity: .fake(),
            price: .fake(),
            sku: .fake(),
            subtotal: .fake(),
            subtotalTax: .fake(),
            taxClass: .fake(),
            taxes: .fake(),
            total: .fake(),
            totalTax: .fake(),
            attributes: .fake(),
            addOns: .fake(),
            image: .fake(),
            parent: .fake(),
            bundleConfiguration: .fake()
        )
    }
}
extension NetworkingCore.OrderItemAttribute {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.OrderItemAttribute {
        .init(
            metaID: .fake(),
            name: .fake(),
            value: .fake()
        )
    }
}
extension NetworkingCore.OrderItemBundleItem {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.OrderItemBundleItem {
        .init(
            bundledItemID: .fake(),
            productID: .fake(),
            quantity: .fake(),
            isOptionalAndSelected: .fake(),
            variationID: .fake(),
            variationAttributes: .fake()
        )
    }
}
extension NetworkingCore.OrderItemProductAddOn {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.OrderItemProductAddOn {
        .init(
            addOnID: .fake(),
            key: .fake(),
            value: .fake()
        )
    }
}
extension NetworkingCore.OrderItemRefund {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.OrderItemRefund {
        .init(
            itemID: .fake(),
            name: .fake(),
            productID: .fake(),
            variationID: .fake(),
            refundedItemID: .fake(),
            quantity: .fake(),
            price: .fake(),
            sku: .fake(),
            subtotal: .fake(),
            subtotalTax: .fake(),
            taxClass: .fake(),
            taxes: .fake(),
            total: .fake(),
            totalTax: .fake()
        )
    }
}
extension NetworkingCore.OrderItemTax {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.OrderItemTax {
        .init(
            taxID: .fake(),
            subtotal: .fake(),
            total: .fake()
        )
    }
}
extension NetworkingCore.OrderItemTaxRefund {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.OrderItemTaxRefund {
        .init(
            taxID: .fake(),
            subtotal: .fake(),
            total: .fake()
        )
    }
}
extension NetworkingCore.OrderNote {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.OrderNote {
        .init(
            noteID: .fake(),
            dateCreated: .fake(),
            note: .fake(),
            isCustomerNote: .fake(),
            author: .fake()
        )
    }
}
extension NetworkingCore.OrderRefundCondensed {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.OrderRefundCondensed {
        .init(
            refundID: .fake(),
            reason: .fake(),
            total: .fake()
        )
    }
}
extension NetworkingCore.OrderStatsV4 {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.OrderStatsV4 {
        .init(
            siteID: .fake(),
            granularity: .fake(),
            totals: .fake(),
            intervals: .fake()
        )
    }
}
extension NetworkingCore.OrderStatsV4Interval {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.OrderStatsV4Interval {
        .init(
            interval: .fake(),
            dateStart: .fake(),
            dateEnd: .fake(),
            subtotals: .fake()
        )
    }
}
extension NetworkingCore.OrderStatsV4Totals {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.OrderStatsV4Totals {
        .init(
            totalOrders: .fake(),
            totalItemsSold: .fake(),
            grossRevenue: .fake(),
            netRevenue: .fake(),
            averageOrderValue: .fake()
        )
    }
}
extension NetworkingCore.OrderStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.OrderStatus {
        .init(
            name: .fake(),
            siteID: .fake(),
            slug: .fake(),
            total: .fake()
        )
    }
}
extension NetworkingCore.OrderStatusEnum {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.OrderStatusEnum {
        .autoDraft
    }
}
extension NetworkingCore.OrderTaxLine {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.OrderTaxLine {
        .init(
            taxID: .fake(),
            rateCode: .fake(),
            rateID: .fake(),
            label: .fake(),
            isCompoundTaxRate: .fake(),
            totalTax: .fake(),
            totalShippingTax: .fake(),
            ratePercent: .fake(),
            attributes: .fake()
        )
    }
}
extension NetworkingCore.ProductVariationAttribute {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.ProductVariationAttribute {
        .init(
            id: .fake(),
            name: .fake(),
            option: .fake()
        )
    }
}
extension NetworkingCore.Refund {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.Refund {
        .init(
            refundID: .fake(),
            orderID: .fake(),
            siteID: .fake(),
            dateCreated: .fake(),
            amount: .fake(),
            reason: .fake(),
            refundedByUserID: .fake(),
            isAutomated: .fake(),
            createAutomated: .fake(),
            items: .fake(),
            shippingLines: .fake()
        )
    }
}
extension NetworkingCore.ShippingLabel {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.ShippingLabel {
        .init(
            siteID: .fake(),
            orderID: .fake(),
            shippingLabelID: .fake(),
            carrierID: .fake(),
            shipmentID: .fake(),
            dateCreated: .fake(),
            packageName: .fake(),
            rate: .fake(),
            currency: .fake(),
            trackingNumber: .fake(),
            serviceName: .fake(),
            refundableAmount: .fake(),
            status: .fake(),
            refund: .fake(),
            originAddress: .fake(),
            destinationAddress: .fake(),
            productIDs: .fake(),
            productNames: .fake(),
            commercialInvoiceURL: .fake(),
            usedDate: .fake(),
            expiryDate: .fake(),
            hazmatCategory: .fake()
        )
    }
}
extension NetworkingCore.ShippingLabelAddress {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.ShippingLabelAddress {
        .init(
            company: .fake(),
            name: .fake(),
            phone: .fake(),
            country: .fake(),
            state: .fake(),
            address1: .fake(),
            address2: .fake(),
            city: .fake(),
            postcode: .fake()
        )
    }
}
extension NetworkingCore.ShippingLabelRefund {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.ShippingLabelRefund {
        .init(
            dateRequested: .fake(),
            status: .fake()
        )
    }
}
extension NetworkingCore.ShippingLabelRefundStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.ShippingLabelRefundStatus {
        .pending
    }
}
extension NetworkingCore.ShippingLabelStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.ShippingLabelStatus {
        .purchased
    }
}
extension NetworkingCore.ShippingLine {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.ShippingLine {
        .init(
            shippingID: .fake(),
            methodTitle: .fake(),
            methodID: .fake(),
            total: .fake(),
            totalTax: .fake(),
            taxes: .fake()
        )
    }
}
extension NetworkingCore.ShippingLineTax {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.ShippingLineTax {
        .init(
            taxID: .fake(),
            subtotal: .fake(),
            total: .fake()
        )
    }
}
extension NetworkingCore.Site {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.Site {
        .init(
            siteID: .fake(),
            name: .fake(),
            description: .fake(),
            url: .fake(),
            adminURL: .fake(),
            loginURL: .fake(),
            isSiteOwner: .fake(),
            frameNonce: .fake(),
            plan: .fake(),
            isAIAssistantFeatureActive: .fake(),
            isJetpackThePluginInstalled: .fake(),
            isJetpackConnected: .fake(),
            isWooCommerceActive: .fake(),
            isWordPressComStore: .fake(),
            jetpackConnectionActivePlugins: .fake(),
            timezone: .fake(),
            gmtOffset: .fake(),
            visibility: .fake(),
            canBlaze: .fake(),
            isAdmin: .fake(),
            wasEcommerceTrial: .fake(),
            hasSSOEnabled: .fake(),
            applicationPasswordAvailable: .fake(),
            isGarden: .fake(),
            gardenName: .fake(),
            gardenPartner: .fake()
        )
    }
}
extension NetworkingCore.SiteSummaryStats {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.SiteSummaryStats {
        .init(
            siteID: .fake(),
            date: .fake(),
            period: .fake(),
            visitors: .fake(),
            views: .fake()
        )
    }
}
extension NetworkingCore.SiteVisibility {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.SiteVisibility {
        .privateSite
    }
}
extension NetworkingCore.SiteVisitStats {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.SiteVisitStats {
        .init(
            siteID: .fake(),
            date: .fake(),
            granularity: .fake(),
            items: .fake()
        )
    }
}
extension NetworkingCore.SiteVisitStatsItem {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.SiteVisitStatsItem {
        .init(
            period: .fake(),
            visitors: .fake(),
            views: .fake()
        )
    }
}
extension NetworkingCore.StatGranularity {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.StatGranularity {
        .day
    }
}
extension NetworkingCore.StatsGranularityV4 {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.StatsGranularityV4 {
        .hourly
    }
}
extension NetworkingCore.User {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NetworkingCore.User {
        .init(
            localID: .fake(),
            siteID: .fake(),
            email: .fake(),
            username: .fake(),
            firstName: .fake(),
            lastName: .fake(),
            nickname: .fake(),
            roles: .fake()
        )
    }
}

// swiftlint:enable line_length
