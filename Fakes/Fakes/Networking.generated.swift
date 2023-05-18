// Generated using Sourcery 1.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Yosemite
import Networking
import Hardware

extension Networking.APNSDevice {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.APNSDevice {
        .init(
            token: .fake(),
            model: .fake(),
            name: .fake(),
            iOSVersion: .fake(),
            identifierForVendor: .fake()
        )
    }
}
extension Networking.Account {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.Account {
        .init(
            userID: .fake(),
            displayName: .fake(),
            email: .fake(),
            username: .fake(),
            gravatarUrl: .fake(),
            ipCountryCode: .fake()
        )
    }
}
extension Networking.AccountSettings {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.AccountSettings {
        .init(
            userID: .fake(),
            tracksOptOut: .fake(),
            firstName: .fake(),
            lastName: .fake()
        )
    }
}
extension AddOnDisplay {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> AddOnDisplay {
        .dropdown
    }
}
extension Networking.AddOnGroup {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.AddOnGroup {
        .init(
            siteID: .fake(),
            groupID: .fake(),
            name: .fake(),
            priority: .fake(),
            addOns: .fake()
        )
    }
}
extension AddOnPriceType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> AddOnPriceType {
        .flatFee
    }
}
extension AddOnRestrictionsType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> AddOnRestrictionsType {
        .any_text
    }
}
extension AddOnTitleFormat {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> AddOnTitleFormat {
        .label
    }
}
extension AddOnType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> AddOnType {
        .multipleChoice
    }
}
extension Networking.Address {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.Address {
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
extension Networking.Announcement {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.Announcement {
        .init(
            appVersionName: .fake(),
            minimumAppVersion: .fake(),
            maximumAppVersion: .fake(),
            appVersionTargets: .fake(),
            detailsUrl: .fake(),
            announcementVersion: .fake(),
            isLocalized: .fake(),
            responseLocale: .fake(),
            features: .fake()
        )
    }
}
extension CompositeComponentOptionType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> CompositeComponentOptionType {
        .productIDs
    }
}
extension Networking.Country {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.Country {
        .init(
            code: .fake(),
            name: .fake(),
            states: .fake()
        )
    }
}
extension Networking.Coupon {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.Coupon {
        .init(
            siteID: .fake(),
            couponID: .fake(),
            code: .fake(),
            amount: .fake(),
            dateCreated: .fake(),
            dateModified: .fake(),
            discountType: .fake(),
            description: .fake(),
            dateExpires: .fake(),
            usageCount: .fake(),
            individualUse: .fake(),
            productIds: .fake(),
            excludedProductIds: .fake(),
            usageLimit: .fake(),
            usageLimitPerUser: .fake(),
            limitUsageToXItems: .fake(),
            freeShipping: .fake(),
            productCategories: .fake(),
            excludedProductCategories: .fake(),
            excludeSaleItems: .fake(),
            minimumAmount: .fake(),
            maximumAmount: .fake(),
            emailRestrictions: .fake(),
            usedBy: .fake()
        )
    }
}
extension Coupon.DiscountType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Coupon.DiscountType {
        .percent
    }
}
extension Networking.CouponReport {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.CouponReport {
        .init(
            couponID: .fake(),
            amount: .fake(),
            ordersCount: .fake()
        )
    }
}
extension Networking.CreateProductVariation {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.CreateProductVariation {
        .init(
            regularPrice: .fake(),
            salePrice: .fake(),
            attributes: .fake(),
            description: .fake(),
            image: .fake()
        )
    }
}
extension Networking.Customer {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.Customer {
        .init(
            siteID: .fake(),
            customerID: .fake(),
            email: .fake(),
            firstName: .fake(),
            lastName: .fake(),
            billing: .fake(),
            shipping: .fake()
        )
    }
}
extension Networking.DomainContactInfo {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.DomainContactInfo {
        .init(
            firstName: .fake(),
            lastName: .fake(),
            organization: .fake(),
            address1: .fake(),
            address2: .fake(),
            postcode: .fake(),
            city: .fake(),
            state: .fake(),
            countryCode: .fake(),
            phone: .fake(),
            email: .fake()
        )
    }
}
extension DotcomError {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> DotcomError {
        .empty
    }
}
extension Networking.DotcomSitePlugin {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.DotcomSitePlugin {
        .init(
            id: .fake(),
            isActive: .fake()
        )
    }
}
extension Networking.DotcomUser {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.DotcomUser {
        .init(
            id: .fake(),
            username: .fake(),
            email: .fake(),
            displayName: .fake(),
            avatar: .fake()
        )
    }
}
extension Networking.Feature {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.Feature {
        .init(
            title: .fake(),
            subtitle: .fake(),
            icons: .fake(),
            iconUrl: .fake(),
            iconBase64: .fake()
        )
    }
}
extension Networking.FeatureIcon {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.FeatureIcon {
        .init(
            iconUrl: .fake(),
            iconBase64: .fake(),
            iconType: .fake()
        )
    }
}
extension Networking.InboxAction {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.InboxAction {
        .init(
            id: .fake(),
            name: .fake(),
            label: .fake(),
            status: .fake(),
            url: .fake()
        )
    }
}
extension Networking.InboxNote {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.InboxNote {
        .init(
            siteID: .fake(),
            id: .fake(),
            name: .fake(),
            type: .fake(),
            status: .fake(),
            actions: .fake(),
            title: .fake(),
            content: .fake(),
            isRemoved: .fake(),
            isRead: .fake(),
            dateCreated: .fake()
        )
    }
}
extension Networking.JetpackUser {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.JetpackUser {
        .init(
            isConnected: .fake(),
            isPrimary: .fake(),
            username: .fake(),
            wpcomUser: .fake(),
            gravatar: .fake()
        )
    }
}
extension Networking.JustInTimeMessage {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.JustInTimeMessage {
        .init(
            siteID: .fake(),
            messageID: .fake(),
            featureClass: .fake(),
            content: .fake(),
            cta: .fake(),
            assets: .fake(),
            template: .fake()
        )
    }
}
extension Networking.JustInTimeMessage.CTA {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.JustInTimeMessage.CTA {
        .init(
            message: .fake(),
            link: .fake()
        )
    }
}
extension Networking.JustInTimeMessage.Content {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.JustInTimeMessage.Content {
        .init(
            message: .fake(),
            description: .fake()
        )
    }
}
extension Networking.Leaderboard {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.Leaderboard {
        .init(
            id: .fake(),
            label: .fake(),
            rows: .fake()
        )
    }
}
extension Networking.Media {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.Media {
        .init(
            mediaID: .fake(),
            date: .fake(),
            fileExtension: .fake(),
            filename: .fake(),
            mimeType: .fake(),
            src: .fake(),
            thumbnailURL: .fake(),
            name: .fake(),
            alt: .fake(),
            height: .fake(),
            width: .fake()
        )
    }
}
extension Networking.Note {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.Note {
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
extension Networking.NoteBlock {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.NoteBlock {
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
extension Networking.NoteMedia {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.NoteMedia {
        .init(
            type: .fake(),
            range: .fake(),
            url: .fake(),
            size: .fake()
        )
    }
}
extension Networking.NoteRange {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.NoteRange {
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
extension Networking.Order {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.Order {
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
            appliedGiftCards: .fake()
        )
    }
}
extension Networking.OrderCouponLine {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.OrderCouponLine {
        .init(
            couponID: .fake(),
            code: .fake(),
            discount: .fake(),
            discountTax: .fake()
        )
    }
}
extension Networking.OrderFeeLine {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.OrderFeeLine {
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
extension OrderFeeTaxStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> OrderFeeTaxStatus {
        .taxable
    }
}
extension Networking.OrderGiftCard {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.OrderGiftCard {
        .init(
            giftCardID: .fake(),
            code: .fake(),
            amount: .fake()
        )
    }
}
extension Networking.OrderItem {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.OrderItem {
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
            parent: .fake()
        )
    }
}
extension Networking.OrderItemAttribute {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.OrderItemAttribute {
        .init(
            metaID: .fake(),
            name: .fake(),
            value: .fake()
        )
    }
}
extension Networking.OrderItemRefund {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.OrderItemRefund {
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
extension Networking.OrderItemTax {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.OrderItemTax {
        .init(
            taxID: .fake(),
            subtotal: .fake(),
            total: .fake()
        )
    }
}
extension Networking.OrderItemTaxRefund {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.OrderItemTaxRefund {
        .init(
            taxID: .fake(),
            subtotal: .fake(),
            total: .fake()
        )
    }
}
extension Networking.OrderNote {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.OrderNote {
        .init(
            noteID: .fake(),
            dateCreated: .fake(),
            note: .fake(),
            isCustomerNote: .fake(),
            author: .fake()
        )
    }
}
extension Networking.OrderRefundCondensed {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.OrderRefundCondensed {
        .init(
            refundID: .fake(),
            reason: .fake(),
            total: .fake()
        )
    }
}
extension Networking.OrderStatsV4 {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.OrderStatsV4 {
        .init(
            siteID: .fake(),
            granularity: .fake(),
            totals: .fake(),
            intervals: .fake()
        )
    }
}
extension Networking.OrderStatsV4Interval {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.OrderStatsV4Interval {
        .init(
            interval: .fake(),
            dateStart: .fake(),
            dateEnd: .fake(),
            subtotals: .fake()
        )
    }
}
extension Networking.OrderStatsV4Totals {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.OrderStatsV4Totals {
        .init(
            totalOrders: .fake(),
            totalItemsSold: .fake(),
            grossRevenue: .fake(),
            couponDiscount: .fake(),
            totalCoupons: .fake(),
            refunds: .fake(),
            taxes: .fake(),
            shipping: .fake(),
            netRevenue: .fake(),
            totalProducts: .fake(),
            averageOrderValue: .fake()
        )
    }
}
extension Networking.OrderStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.OrderStatus {
        .init(
            name: .fake(),
            siteID: .fake(),
            slug: .fake(),
            total: .fake()
        )
    }
}
extension OrderStatusEnum {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> OrderStatusEnum {
        .autoDraft
    }
}
extension Networking.OrderTaxLine {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.OrderTaxLine {
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
extension Networking.PaymentGateway {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.PaymentGateway {
        .init(
            siteID: .fake(),
            gatewayID: .fake(),
            title: .fake(),
            description: .fake(),
            enabled: .fake(),
            features: .fake(),
            instructions: .fake()
        )
    }
}
extension Networking.PaymentGateway.Setting {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.PaymentGateway.Setting {
        .init(
            settingID: .fake(),
            value: .fake()
        )
    }
}
extension Networking.PaymentGatewayAccount {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.PaymentGatewayAccount {
        .init(
            siteID: .fake(),
            gatewayID: .fake(),
            status: .fake(),
            hasPendingRequirements: .fake(),
            hasOverdueRequirements: .fake(),
            currentDeadline: .fake(),
            statementDescriptor: .fake(),
            defaultCurrency: .fake(),
            supportedCurrencies: .fake(),
            country: .fake(),
            isCardPresentEligible: .fake(),
            isLive: .fake(),
            isInTestMode: .fake()
        )
    }
}
extension Networking.Post {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.Post {
        .init(
            siteID: .fake(),
            password: .fake()
        )
    }
}
extension Networking.Product {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.Product {
        .init(
            siteID: .fake(),
            productID: .fake(),
            name: .fake(),
            slug: .fake(),
            permalink: .fake(),
            date: .fake(),
            dateCreated: .fake(),
            dateModified: .fake(),
            dateOnSaleStart: .fake(),
            dateOnSaleEnd: .fake(),
            productTypeKey: .fake(),
            statusKey: .fake(),
            featured: .fake(),
            catalogVisibilityKey: .fake(),
            fullDescription: .fake(),
            shortDescription: .fake(),
            sku: .fake(),
            price: .fake(),
            regularPrice: .fake(),
            salePrice: .fake(),
            onSale: .fake(),
            purchasable: .fake(),
            totalSales: .fake(),
            virtual: .fake(),
            downloadable: .fake(),
            downloads: .fake(),
            downloadLimit: .fake(),
            downloadExpiry: .fake(),
            buttonText: .fake(),
            externalURL: .fake(),
            taxStatusKey: .fake(),
            taxClass: .fake(),
            manageStock: .fake(),
            stockQuantity: .fake(),
            stockStatusKey: .fake(),
            backordersKey: .fake(),
            backordersAllowed: .fake(),
            backordered: .fake(),
            soldIndividually: .fake(),
            weight: .fake(),
            dimensions: .fake(),
            shippingRequired: .fake(),
            shippingTaxable: .fake(),
            shippingClass: .fake(),
            shippingClassID: .fake(),
            productShippingClass: .fake(),
            reviewsAllowed: .fake(),
            averageRating: .fake(),
            ratingCount: .fake(),
            relatedIDs: .fake(),
            upsellIDs: .fake(),
            crossSellIDs: .fake(),
            parentID: .fake(),
            purchaseNote: .fake(),
            categories: .fake(),
            tags: .fake(),
            images: .fake(),
            attributes: .fake(),
            defaultAttributes: .fake(),
            variations: .fake(),
            groupedProducts: .fake(),
            menuOrder: .fake(),
            addOns: .fake(),
            bundleStockStatus: .fake(),
            bundleStockQuantity: .fake(),
            bundledItems: .fake(),
            compositeComponents: .fake(),
            subscription: .fake(),
            minAllowedQuantity: .fake(),
            maxAllowedQuantity: .fake(),
            groupOfQuantity: .fake(),
            combineVariationQuantities: .fake()
        )
    }
}
extension Networking.ProductAddOn {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductAddOn {
        .init(
            type: .fake(),
            display: .fake(),
            name: .fake(),
            titleFormat: .fake(),
            descriptionEnabled: .fake(),
            description: .fake(),
            required: .fake(),
            position: .fake(),
            restrictions: .fake(),
            restrictionsType: .fake(),
            adjustPrice: .fake(),
            priceType: .fake(),
            price: .fake(),
            min: .fake(),
            max: .fake(),
            options: .fake()
        )
    }
}
extension Networking.ProductAddOnOption {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductAddOnOption {
        .init(
            label: .fake(),
            price: .fake(),
            priceType: .fake(),
            imageID: .fake()
        )
    }
}
extension Networking.ProductAttribute {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductAttribute {
        .init(
            siteID: .fake(),
            attributeID: .fake(),
            name: .fake(),
            position: .fake(),
            visible: .fake(),
            variation: .fake(),
            options: .fake()
        )
    }
}
extension Networking.ProductAttributeTerm {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductAttributeTerm {
        .init(
            siteID: .fake(),
            termID: .fake(),
            name: .fake(),
            slug: .fake(),
            count: .fake()
        )
    }
}
extension ProductBackordersSetting {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductBackordersSetting {
        .allowed
    }
}
extension Networking.ProductBundleItem {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductBundleItem {
        .init(
            bundledItemID: .fake(),
            productID: .fake(),
            menuOrder: .fake(),
            title: .fake(),
            stockStatus: .fake()
        )
    }
}
extension ProductBundleItemStockStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductBundleItemStockStatus {
        .inStock
    }
}
extension ProductCatalogVisibility {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductCatalogVisibility {
        .visible
    }
}
extension Networking.ProductCategory {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductCategory {
        .init(
            categoryID: .fake(),
            siteID: .fake(),
            parentID: .fake(),
            name: .fake(),
            slug: .fake()
        )
    }
}
extension Networking.ProductCompositeComponent {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductCompositeComponent {
        .init(
            componentID: .fake(),
            title: .fake(),
            description: .fake(),
            imageURL: .fake(),
            optionType: .fake(),
            optionIDs: .fake(),
            defaultOptionID: .fake()
        )
    }
}
extension Networking.ProductDefaultAttribute {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductDefaultAttribute {
        .init(
            attributeID: .fake(),
            name: .fake(),
            option: .fake()
        )
    }
}
extension Networking.ProductDimensions {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductDimensions {
        .init(
            length: .fake(),
            width: .fake(),
            height: .fake()
        )
    }
}
extension Networking.ProductDownload {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductDownload {
        .init(
            downloadID: .fake(),
            name: .fake(),
            fileURL: .fake()
        )
    }
}
extension Networking.ProductDownloadDragAndDrop {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductDownloadDragAndDrop {
        .init(
            downloadableFile: .fake()
        )
    }
}
extension Networking.ProductImage {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductImage {
        .init(
            imageID: .fake(),
            dateCreated: .fake(),
            dateModified: .fake(),
            src: .fake(),
            name: .fake(),
            alt: .fake()
        )
    }
}
extension Networking.ProductReview {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductReview {
        .init(
            siteID: .fake(),
            reviewID: .fake(),
            productID: .fake(),
            dateCreated: .fake(),
            statusKey: .fake(),
            reviewer: .fake(),
            reviewerEmail: .fake(),
            reviewerAvatarURL: .fake(),
            review: .fake(),
            rating: .fake(),
            verified: .fake()
        )
    }
}
extension ProductReviewStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductReviewStatus {
        .approved
    }
}
extension Networking.ProductShippingClass {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductShippingClass {
        .init(
            count: .fake(),
            descriptionHTML: .fake(),
            name: .fake(),
            shippingClassID: .fake(),
            siteID: .fake(),
            slug: .fake()
        )
    }
}
extension ProductStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductStatus {
        .published
    }
}
extension ProductStockStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductStockStatus {
        .inStock
    }
}
extension Networking.ProductSubscription {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductSubscription {
        .init(
            length: .fake(),
            period: .fake(),
            periodInterval: .fake(),
            price: .fake(),
            signUpFee: .fake(),
            trialLength: .fake(),
            trialPeriod: .fake()
        )
    }
}
extension Networking.ProductTag {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductTag {
        .init(
            siteID: .fake(),
            tagID: .fake(),
            name: .fake(),
            slug: .fake()
        )
    }
}
extension ProductTaxStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductTaxStatus {
        .taxable
    }
}
extension ProductType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductType {
        .simple
    }
}
extension Networking.ProductVariation {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductVariation {
        .init(
            siteID: .fake(),
            productID: .fake(),
            productVariationID: .fake(),
            attributes: .fake(),
            image: .fake(),
            permalink: .fake(),
            dateCreated: .fake(),
            dateModified: .fake(),
            dateOnSaleStart: .fake(),
            dateOnSaleEnd: .fake(),
            status: .fake(),
            description: .fake(),
            sku: .fake(),
            price: .fake(),
            regularPrice: .fake(),
            salePrice: .fake(),
            onSale: .fake(),
            purchasable: .fake(),
            virtual: .fake(),
            downloadable: .fake(),
            downloads: .fake(),
            downloadLimit: .fake(),
            downloadExpiry: .fake(),
            taxStatusKey: .fake(),
            taxClass: .fake(),
            manageStock: .fake(),
            stockQuantity: .fake(),
            stockStatus: .fake(),
            backordersKey: .fake(),
            backordersAllowed: .fake(),
            backordered: .fake(),
            weight: .fake(),
            dimensions: .fake(),
            shippingClass: .fake(),
            shippingClassID: .fake(),
            menuOrder: .fake(),
            subscription: .fake(),
            minAllowedQuantity: .fake(),
            maxAllowedQuantity: .fake(),
            groupOfQuantity: .fake(),
            overrideProductQuantities: .fake()
        )
    }
}
extension Networking.ProductVariationAttribute {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductVariationAttribute {
        .init(
            id: .fake(),
            name: .fake(),
            option: .fake()
        )
    }
}
extension Networking.Refund {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.Refund {
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
extension Networking.ShipmentTracking {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShipmentTracking {
        .init(
            siteID: .fake(),
            orderID: .fake(),
            trackingID: .fake(),
            trackingNumber: .fake(),
            trackingProvider: .fake(),
            trackingURL: .fake(),
            dateShipped: .fake()
        )
    }
}
extension Networking.ShipmentTrackingProvider {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShipmentTrackingProvider {
        .init(
            siteID: .fake(),
            name: .fake(),
            url: .fake()
        )
    }
}
extension Networking.ShipmentTrackingProviderGroup {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShipmentTrackingProviderGroup {
        .init(
            name: .fake(),
            siteID: .fake(),
            providers: .fake()
        )
    }
}
extension Networking.ShippingLabel {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabel {
        .init(
            siteID: .fake(),
            orderID: .fake(),
            shippingLabelID: .fake(),
            carrierID: .fake(),
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
            commercialInvoiceURL: .fake()
        )
    }
}
extension Networking.ShippingLabelAccountSettings {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelAccountSettings {
        .init(
            siteID: .fake(),
            canManagePayments: .fake(),
            canEditSettings: .fake(),
            storeOwnerDisplayName: .fake(),
            storeOwnerUsername: .fake(),
            storeOwnerWpcomUsername: .fake(),
            storeOwnerWpcomEmail: .fake(),
            paymentMethods: .fake(),
            selectedPaymentMethodID: .fake(),
            isEmailReceiptsEnabled: .fake(),
            paperSize: .fake(),
            lastSelectedPackageID: .fake()
        )
    }
}
extension Networking.ShippingLabelAddress {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelAddress {
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
extension Networking.ShippingLabelAddressValidationError {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelAddressValidationError {
        .init(
            addressError: .fake(),
            generalError: .fake()
        )
    }
}
extension Networking.ShippingLabelAddressValidationSuccess {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelAddressValidationSuccess {
        .init(
            address: .fake(),
            isTrivialNormalization: .fake()
        )
    }
}
extension Networking.ShippingLabelAddressVerification {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelAddressVerification {
        .init(
            address: .fake(),
            type: .fake()
        )
    }
}
extension ShippingLabelAddressVerification.ShipType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelAddressVerification.ShipType {
        .origin
    }
}
extension Networking.ShippingLabelCarrierRate {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelCarrierRate {
        .init(
            title: .fake(),
            insurance: .fake(),
            retailRate: .fake(),
            rate: .fake(),
            rateID: .fake(),
            serviceID: .fake(),
            carrierID: .fake(),
            shipmentID: .fake(),
            hasTracking: .fake(),
            isSelected: .fake(),
            isPickupFree: .fake(),
            deliveryDays: .fake(),
            deliveryDateGuaranteed: .fake()
        )
    }
}
extension Networking.ShippingLabelCreationEligibilityResponse {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelCreationEligibilityResponse {
        .init(
            isEligible: .fake(),
            reason: .fake()
        )
    }
}
extension Networking.ShippingLabelCustomPackage {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelCustomPackage {
        .init(
            isUserDefined: .fake(),
            title: .fake(),
            isLetter: .fake(),
            dimensions: .fake(),
            boxWeight: .fake(),
            maxWeight: .fake()
        )
    }
}
extension Networking.ShippingLabelCustomsForm {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelCustomsForm {
        .init(
            packageID: .fake(),
            packageName: .fake(),
            contentsType: .fake(),
            contentExplanation: .fake(),
            restrictionType: .fake(),
            restrictionComments: .fake(),
            nonDeliveryOption: .fake(),
            itn: .fake(),
            items: .fake()
        )
    }
}
extension ShippingLabelCustomsForm.ContentsType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelCustomsForm.ContentsType {
        .merchandise
    }
}
extension Networking.ShippingLabelCustomsForm.Item {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelCustomsForm.Item {
        .init(
            description: .fake(),
            quantity: .fake(),
            value: .fake(),
            weight: .fake(),
            hsTariffNumber: .fake(),
            originCountry: .fake(),
            productID: .fake()
        )
    }
}
extension ShippingLabelCustomsForm.NonDeliveryOption {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelCustomsForm.NonDeliveryOption {
        .`return`
    }
}
extension ShippingLabelCustomsForm.RestrictionType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelCustomsForm.RestrictionType {
        .none
    }
}
extension Networking.ShippingLabelPackagePurchase {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelPackagePurchase {
        .init(
            package: .fake(),
            rate: .fake(),
            productIDs: .fake(),
            customsForm: .fake()
        )
    }
}
extension Networking.ShippingLabelPackageSelected {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelPackageSelected {
        .init(
            id: .fake(),
            boxID: .fake(),
            length: .fake(),
            width: .fake(),
            height: .fake(),
            weight: .fake(),
            isLetter: .fake(),
            customsForm: .fake()
        )
    }
}
extension Networking.ShippingLabelPackagesResponse {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelPackagesResponse {
        .init(
            storeOptions: .fake(),
            customPackages: .fake(),
            predefinedOptions: .fake(),
            unactivatedPredefinedOptions: .fake()
        )
    }
}
extension ShippingLabelPaperSize {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelPaperSize {
        .a4
    }
}
extension ShippingLabelPaymentCardType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelPaymentCardType {
        .amex
    }
}
extension Networking.ShippingLabelPaymentMethod {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelPaymentMethod {
        .init(
            paymentMethodID: .fake(),
            name: .fake(),
            cardType: .fake(),
            cardDigits: .fake(),
            expiry: .fake()
        )
    }
}
extension Networking.ShippingLabelPredefinedOption {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelPredefinedOption {
        .init(
            title: .fake(),
            providerID: .fake(),
            predefinedPackages: .fake()
        )
    }
}
extension Networking.ShippingLabelPredefinedPackage {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelPredefinedPackage {
        .init(
            id: .fake(),
            title: .fake(),
            isLetter: .fake(),
            dimensions: .fake()
        )
    }
}
extension Networking.ShippingLabelPrintData {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelPrintData {
        .init(
            mimeType: .fake(),
            base64Content: .fake()
        )
    }
}
extension Networking.ShippingLabelPurchase {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelPurchase {
        .init(
            siteID: .fake(),
            orderID: .fake(),
            shippingLabelID: .fake(),
            carrierID: .fake(),
            dateCreated: .fake(),
            packageName: .fake(),
            trackingNumber: .fake(),
            serviceName: .fake(),
            refundableAmount: .fake(),
            status: .fake(),
            productIDs: .fake(),
            productNames: .fake()
        )
    }
}
extension Networking.ShippingLabelRefund {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelRefund {
        .init(
            dateRequested: .fake(),
            status: .fake()
        )
    }
}
extension ShippingLabelRefundStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelRefundStatus {
        .pending
    }
}
extension Networking.ShippingLabelSettings {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelSettings {
        .init(
            siteID: .fake(),
            orderID: .fake(),
            paperSize: .fake()
        )
    }
}
extension ShippingLabelStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelStatus {
        .purchased
    }
}
extension Networking.ShippingLabelStoreOptions {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelStoreOptions {
        .init(
            currencySymbol: .fake(),
            dimensionUnit: .fake(),
            weightUnit: .fake(),
            originCountry: .fake()
        )
    }
}
extension Networking.ShippingLine {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLine {
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
extension Networking.ShippingLineTax {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLineTax {
        .init(
            taxID: .fake(),
            subtotal: .fake(),
            total: .fake()
        )
    }
}
extension Networking.Site {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.Site {
        .init(
            siteID: .fake(),
            name: .fake(),
            description: .fake(),
            url: .fake(),
            adminURL: .fake(),
            loginURL: .fake(),
            frameNonce: .fake(),
            plan: .fake(),
            isJetpackThePluginInstalled: .fake(),
            isJetpackConnected: .fake(),
            isWooCommerceActive: .fake(),
            isWordPressComStore: .fake(),
            jetpackConnectionActivePlugins: .fake(),
            timezone: .fake(),
            gmtOffset: .fake(),
            isPublic: .fake()
        )
    }
}
extension Networking.SiteAPI {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.SiteAPI {
        .init(
            siteID: .fake(),
            namespaces: .fake()
        )
    }
}
extension Networking.SitePlan {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.SitePlan {
        .init(
            siteID: .fake(),
            shortName: .fake()
        )
    }
}
extension Networking.SitePlugin {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.SitePlugin {
        .init(
            siteID: .fake(),
            plugin: .fake(),
            status: .fake(),
            name: .fake(),
            pluginUri: .fake(),
            author: .fake(),
            authorUri: .fake(),
            descriptionRaw: .fake(),
            descriptionRendered: .fake(),
            version: .fake(),
            networkOnly: .fake(),
            requiresWPVersion: .fake(),
            requiresPHPVersion: .fake(),
            textDomain: .fake()
        )
    }
}
extension SitePluginStatusEnum {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> SitePluginStatusEnum {
        .active
    }
}
extension Networking.SiteSetting {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.SiteSetting {
        .init(
            siteID: .fake(),
            settingID: .fake(),
            label: .fake(),
            settingDescription: .fake(),
            value: .fake(),
            settingGroupKey: .fake()
        )
    }
}
extension SiteSettingGroup {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> SiteSettingGroup {
        .general
    }
}
extension Networking.SiteSummaryStats {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.SiteSummaryStats {
        .init(
            siteID: .fake(),
            date: .fake(),
            period: .fake(),
            visitors: .fake(),
            views: .fake()
        )
    }
}
extension Networking.SiteVisitStats {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.SiteVisitStats {
        .init(
            siteID: .fake(),
            date: .fake(),
            granularity: .fake(),
            items: .fake()
        )
    }
}
extension Networking.SiteVisitStatsItem {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.SiteVisitStatsItem {
        .init(
            period: .fake(),
            visitors: .fake(),
            views: .fake()
        )
    }
}
extension StatGranularity {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> StatGranularity {
        .day
    }
}
extension Networking.StateOfACountry {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.StateOfACountry {
        .init(
            code: .fake(),
            name: .fake()
        )
    }
}
extension StatsGranularityV4 {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> StatsGranularityV4 {
        .hourly
    }
}
extension Networking.StoredProductSettings {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.StoredProductSettings {
        .init(
            settings: .fake()
        )
    }
}
extension Networking.Subscription {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.Subscription {
        .init(
            siteID: .fake(),
            subscriptionID: .fake(),
            parentID: .fake(),
            status: .fake(),
            currency: .fake(),
            billingPeriod: .fake(),
            billingInterval: .fake(),
            total: .fake(),
            startDate: .fake(),
            endDate: .fake()
        )
    }
}
extension SubscriptionPeriod {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> SubscriptionPeriod {
        .day
    }
}
extension SubscriptionStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> SubscriptionStatus {
        .pending
    }
}
extension Networking.SystemPlugin {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.SystemPlugin {
        .init(
            siteID: .fake(),
            plugin: .fake(),
            name: .fake(),
            version: .fake(),
            versionLatest: .fake(),
            url: .fake(),
            authorName: .fake(),
            authorUrl: .fake(),
            networkActivated: .fake(),
            active: .fake()
        )
    }
}
extension Networking.TaxClass {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.TaxClass {
        .init(
            siteID: .fake(),
            name: .fake(),
            slug: .fake()
        )
    }
}
extension Networking.TopEarnerStats {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.TopEarnerStats {
        .init(
            siteID: .fake(),
            date: .fake(),
            granularity: .fake(),
            limit: .fake(),
            items: .fake()
        )
    }
}
extension Networking.TopEarnerStatsItem {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.TopEarnerStatsItem {
        .init(
            productID: .fake(),
            productName: .fake(),
            quantity: .fake(),
            price: .fake(),
            total: .fake(),
            currency: .fake(),
            imageUrl: .fake()
        )
    }
}
extension Networking.UploadableMedia {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.UploadableMedia {
        .init(
            localURL: .fake(),
            filename: .fake(),
            mimeType: .fake()
        )
    }
}
extension Networking.User {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.User {
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
extension Networking.WCAnalyticsCustomer {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WCAnalyticsCustomer {
        .init(
            siteID: .fake(),
            userID: .fake(),
            name: .fake()
        )
    }
}
extension WCPayAccountStatusEnum {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> WCPayAccountStatusEnum {
        .complete
    }
}
extension WCPayCardBrand {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> WCPayCardBrand {
        .amex
    }
}
extension WCPayCardFunding {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> WCPayCardFunding {
        .credit
    }
}
extension Networking.WCPayCardPaymentDetails {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WCPayCardPaymentDetails {
        .init(
            brand: .fake(),
            last4: .fake(),
            funding: .fake()
        )
    }
}
extension Networking.WCPayCardPresentPaymentDetails {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WCPayCardPresentPaymentDetails {
        .init(
            brand: .fake(),
            last4: .fake(),
            funding: .fake(),
            receipt: .fake()
        )
    }
}
extension Networking.WCPayCardPresentReceiptDetails {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WCPayCardPresentReceiptDetails {
        .init(
            accountType: .fake(),
            applicationPreferredName: .fake(),
            dedicatedFileName: .fake()
        )
    }
}
extension Networking.WCPayCharge {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WCPayCharge {
        .init(
            siteID: .fake(),
            id: .fake(),
            amount: .fake(),
            amountCaptured: .fake(),
            amountRefunded: .fake(),
            authorizationCode: .fake(),
            captured: .fake(),
            created: .fake(),
            currency: .fake(),
            paid: .fake(),
            paymentIntentID: .fake(),
            paymentMethodID: .fake(),
            paymentMethodDetails: .fake(),
            refunded: .fake(),
            status: .fake()
        )
    }
}
extension WCPayChargeStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> WCPayChargeStatus {
        .succeeded
    }
}
extension WCPayPaymentIntentStatusEnum {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> WCPayPaymentIntentStatusEnum {
        .requiresPaymentMethod
    }
}
extension WCPayPaymentMethodDetails {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> WCPayPaymentMethodDetails {
        .unknown
    }
}
extension WCPayPaymentMethodType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> WCPayPaymentMethodType {
        .card
    }
}
extension Networking.WordPressMedia {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WordPressMedia {
        .init(
            mediaID: .fake(),
            date: .fake(),
            slug: .fake(),
            mimeType: .fake(),
            src: .fake(),
            alt: .fake(),
            details: .fake(),
            title: .fake()
        )
    }
}
