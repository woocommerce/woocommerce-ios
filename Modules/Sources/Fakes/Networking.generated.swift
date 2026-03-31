// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Yosemite
import Networking
import Hardware
import WooFoundation

// swiftlint:disable line_length

extension Networking.AIProduct {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.AIProduct {
        .init(
            names: .fake(),
            descriptions: .fake(),
            shortDescriptions: .fake(),
            virtual: .fake(),
            shipping: .fake(),
            tags: .fake(),
            price: .fake(),
            categories: .fake()
        )
    }
}
extension Networking.AIProduct.Shipping {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.AIProduct.Shipping {
        .init(
            length: .fake(),
            weight: .fake(),
            width: .fake(),
            height: .fake()
        )
    }
}
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
extension Networking.AddOnDisplay {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.AddOnDisplay {
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
extension Networking.AddOnPriceType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.AddOnPriceType {
        .flatFee
    }
}
extension Networking.AddOnRestrictionsType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.AddOnRestrictionsType {
        .any_text
    }
}
extension Networking.AddOnTitleFormat {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.AddOnTitleFormat {
        .label
    }
}
extension Networking.AddOnType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.AddOnType {
        .multipleChoice
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
extension Networking.BlazeAISuggestion {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.BlazeAISuggestion {
        .init(
            siteName: .fake(),
            textSnippet: .fake(),
            ctaText: .fake()
        )
    }
}
extension Networking.BlazeCampaignBudget {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.BlazeCampaignBudget {
        .init(
            mode: .fake(),
            amount: .fake(),
            currency: .fake()
        )
    }
}
extension Networking.BlazeCampaignBudget.Mode {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.BlazeCampaignBudget.Mode {
        .total
    }
}
extension Networking.BlazeCampaignListItem {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.BlazeCampaignListItem {
        .init(
            siteID: .fake(),
            campaignID: .fake(),
            productID: .fake(),
            name: .fake(),
            textSnippet: .fake(),
            uiStatus: .fake(),
            imageURL: .fake(),
            targetUrl: .fake(),
            impressions: .fake(),
            clicks: .fake(),
            totalBudget: .fake(),
            spentBudget: .fake(),
            budgetMode: .fake(),
            budgetAmount: .fake(),
            budgetCurrency: .fake(),
            isEvergreen: .fake(),
            durationDays: .fake(),
            startTime: .fake()
        )
    }
}
extension Networking.BlazeCampaignObjective {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.BlazeCampaignObjective {
        .init(
            id: .fake(),
            title: .fake(),
            description: .fake(),
            suitableForDescription: .fake(),
            locale: .fake()
        )
    }
}
extension Networking.BlazeForecastedImpressionsInput {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.BlazeForecastedImpressionsInput {
        .init(
            startDate: .fake(),
            endDate: .fake(),
            timeZone: .fake(),
            totalBudget: .fake(),
            targeting: .fake(),
            isEvergreen: .fake()
        )
    }
}
extension Networking.BlazeImpressions {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.BlazeImpressions {
        .init(
            totalImpressionsMin: .fake(),
            totalImpressionsMax: .fake()
        )
    }
}
extension Networking.BlazePaymentInfo {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.BlazePaymentInfo {
        .init(
            paymentMethods: .fake()
        )
    }
}
extension Networking.BlazePaymentMethod {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.BlazePaymentMethod {
        .init(
            id: .fake(),
            rawType: .fake(),
            name: .fake(),
            info: .fake()
        )
    }
}
extension Networking.BlazePaymentMethod.ExpiringInfo {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.BlazePaymentMethod.ExpiringInfo {
        .init(
            year: .fake(),
            month: .fake()
        )
    }
}
extension Networking.BlazePaymentMethod.Info {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.BlazePaymentMethod.Info {
        .init(
            lastDigits: .fake(),
            expiring: .fake(),
            type: .fake(),
            nickname: .fake(),
            cardholderName: .fake()
        )
    }
}
extension Networking.BlazeTargetDevice {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.BlazeTargetDevice {
        .init(
            id: .fake(),
            name: .fake(),
            locale: .fake()
        )
    }
}
extension Networking.BlazeTargetLanguage {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.BlazeTargetLanguage {
        .init(
            id: .fake(),
            name: .fake(),
            locale: .fake()
        )
    }
}
extension Networking.BlazeTargetLocation {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.BlazeTargetLocation {
        .init(
            id: .fake(),
            name: .fake(),
            type: .fake(),
            parentLocation: .fake()
        )
    }
}
extension Networking.BlazeTargetOptions {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.BlazeTargetOptions {
        .init(
            locations: .fake(),
            languages: .fake(),
            devices: .fake(),
            pageTopics: .fake()
        )
    }
}
extension Networking.BlazeTargetTopic {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.BlazeTargetTopic {
        .init(
            id: .fake(),
            name: .fake(),
            locale: .fake()
        )
    }
}
extension Networking.Booking {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.Booking {
        .init(
            siteID: .fake(),
            bookingID: .fake(),
            allDay: .fake(),
            cost: .fake(),
            customerID: .fake(),
            userID: .fake(),
            dateCreated: .fake(),
            dateModified: .fake(),
            endDate: .fake(),
            googleCalendarEventID: .fake(),
            orderID: .fake(),
            orderItemID: .fake(),
            parentID: .fake(),
            productID: .fake(),
            resourceID: .fake(),
            startDate: .fake(),
            statusKey: .fake(),
            attendanceStatusKey: .fake(),
            localTimezone: .fake(),
            currency: .fake(),
            orderInfo: .fake(),
            note: .fake()
        )
    }
}
extension Networking.BookingResource {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.BookingResource {
        .init(
            siteID: .fake(),
            resourceID: .fake(),
            name: .fake(),
            quantity: .fake(),
            role: .fake(),
            email: .fake(),
            phoneNumber: .fake(),
            imageID: .fake(),
            imageURL: .fake(),
            description: .fake()
        )
    }
}
extension Networking.CompositeComponentOptionType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.CompositeComponentOptionType {
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
extension Networking.Coupon.DiscountType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.Coupon.DiscountType {
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
extension Networking.CreateBlazeCampaign {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.CreateBlazeCampaign {
        .init(
            origin: .fake(),
            originVersion: .fake(),
            paymentMethodID: .fake(),
            startDate: .fake(),
            endDate: .fake(),
            timeZone: .fake(),
            budget: .fake(),
            isEvergreen: .fake(),
            siteName: .fake(),
            textSnippet: .fake(),
            targetUrl: .fake(),
            urlParams: .fake(),
            mainImage: .fake(),
            targeting: .fake(),
            targetUrn: .fake(),
            type: .fake(),
            objective: .fake(),
            ctaText: .fake(),
            acceptedTOS: .fake()
        )
    }
}
extension Networking.CreateBlazeCampaign.Image {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.CreateBlazeCampaign.Image {
        .init(
            url: .fake(),
            mimeType: .fake()
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
            image: .fake(),
            subscription: .fake()
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
            username: .fake(),
            firstName: .fake(),
            lastName: .fake(),
            billing: .fake(),
            shipping: .fake()
        )
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
extension Networking.GiftCardStats {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.GiftCardStats {
        .init(
            siteID: .fake(),
            granularity: .fake(),
            totals: .fake(),
            intervals: .fake()
        )
    }
}
extension Networking.GiftCardStatsInterval {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.GiftCardStatsInterval {
        .init(
            interval: .fake(),
            dateStart: .fake(),
            dateEnd: .fake(),
            subtotals: .fake()
        )
    }
}
extension Networking.GiftCardStatsTotals {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.GiftCardStatsTotals {
        .init(
            giftCardsCount: .fake(),
            usedAmount: .fake(),
            refundedAmount: .fake(),
            netAmount: .fake()
        )
    }
}
extension Networking.GoogleAdsCampaign {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.GoogleAdsCampaign {
        .init(
            id: .fake(),
            name: .fake(),
            rawStatus: .fake(),
            rawType: .fake(),
            amount: .fake(),
            country: .fake(),
            targetedLocations: .fake()
        )
    }
}
extension Networking.GoogleAdsCampaignStats {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.GoogleAdsCampaignStats {
        .init(
            siteID: .fake(),
            totals: .fake(),
            campaigns: .fake(),
            nextPageToken: .fake()
        )
    }
}
extension Networking.GoogleAdsCampaignStatsItem {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.GoogleAdsCampaignStatsItem {
        .init(
            campaignID: .fake(),
            campaignName: .fake(),
            rawStatus: .fake(),
            subtotals: .fake()
        )
    }
}
extension Networking.GoogleAdsCampaignStatsTotals {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.GoogleAdsCampaignStatsTotals {
        .init(
            sales: .fake(),
            spend: .fake(),
            clicks: .fake(),
            impressions: .fake(),
            conversions: .fake()
        )
    }
}
extension Networking.GoogleAdsConnection {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.GoogleAdsConnection {
        .init(
            id: .fake(),
            currency: .fake(),
            symbol: .fake(),
            rawStatus: .fake()
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
extension Networking.JetpackConnectionData {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.JetpackConnectionData {
        .init(
            currentUser: .fake(),
            isRegistered: .fake(),
            connectionOwner: .fake(),
            blogID: .fake()
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
            gravatar: .fake(),
            blogID: .fake()
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
extension Networking.POSProduct {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.POSProduct {
        .init(
            siteID: .fake(),
            productID: .fake(),
            name: .fake(),
            productTypeKey: .fake(),
            fullDescription: .fake(),
            shortDescription: .fake(),
            sku: .fake(),
            globalUniqueID: .fake(),
            price: .fake(),
            downloadable: .fake(),
            parentID: .fake(),
            images: .fake(),
            attributes: .fake(),
            manageStock: .fake(),
            stockQuantity: .fake(),
            stockStatusKey: .fake(),
            statusKey: .fake(),
            variationIDs: .fake()
        )
    }
}
extension Networking.POSProductVariation {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.POSProductVariation {
        .init(
            siteID: .fake(),
            productID: .fake(),
            productVariationID: .fake(),
            attributes: .fake(),
            image: .fake(),
            fullDescription: .fake(),
            sku: .fake(),
            globalUniqueID: .fake(),
            price: .fake(),
            downloadable: .fake(),
            manageStock: .fake(),
            stockQuantity: .fake(),
            stockStatusKey: .fake()
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
            globalUniqueID: .fake(),
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
            isSampleItem: .fake(),
            bundleStockStatus: .fake(),
            bundleStockQuantity: .fake(),
            bundleMinSize: .fake(),
            bundleMaxSize: .fake(),
            bundledItems: .fake(),
            password: .fake(),
            compositeComponents: .fake(),
            subscription: .fake(),
            minAllowedQuantity: .fake(),
            maxAllowedQuantity: .fake(),
            groupOfQuantity: .fake(),
            combineVariationQuantities: .fake(),
            customFields: .fake()
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
extension Networking.ProductBackordersSetting {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductBackordersSetting {
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
            stockStatus: .fake(),
            minQuantity: .fake(),
            maxQuantity: .fake(),
            defaultQuantity: .fake(),
            isOptional: .fake(),
            overridesVariations: .fake(),
            allowedVariations: .fake(),
            overridesDefaultVariationAttributes: .fake(),
            defaultVariationAttributes: .fake(),
            pricedIndividually: .fake()
        )
    }
}
extension Networking.ProductBundleItemStockStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductBundleItemStockStatus {
        .inStock
    }
}
extension Networking.ProductBundleStats {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductBundleStats {
        .init(
            siteID: .fake(),
            granularity: .fake(),
            totals: .fake(),
            intervals: .fake()
        )
    }
}
extension Networking.ProductBundleStatsInterval {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductBundleStatsInterval {
        .init(
            interval: .fake(),
            dateStart: .fake(),
            dateEnd: .fake(),
            subtotals: .fake()
        )
    }
}
extension Networking.ProductBundleStatsTotals {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductBundleStatsTotals {
        .init(
            totalItemsSold: .fake(),
            totalBundledItemsSold: .fake(),
            netRevenue: .fake(),
            totalOrders: .fake(),
            totalProducts: .fake()
        )
    }
}
extension Networking.ProductCatalogVisibility {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductCatalogVisibility {
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
extension Networking.ProductReport {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductReport {
        .init(
            productID: .fake(),
            variationID: .fake(),
            name: .fake(),
            imageURL: .fake(),
            itemsSold: .fake(),
            stockQuantity: .fake()
        )
    }
}
extension Networking.ProductReport.ExtendedInfo {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductReport.ExtendedInfo {
        .init(
            name: .fake(),
            image: .fake(),
            stockQuantity: .fake()
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
extension Networking.ProductReviewStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductReviewStatus {
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
extension Networking.ProductStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductStatus {
        .published
    }
}
extension Networking.ProductStock {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductStock {
        .init(
            siteID: .fake(),
            productID: .fake(),
            parentID: .fake(),
            name: .fake(),
            sku: .fake(),
            manageStock: .fake(),
            stockQuantity: .fake(),
            stockStatusKey: .fake()
        )
    }
}
extension Networking.ProductStockStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductStockStatus {
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
            trialPeriod: .fake(),
            oneTimeShipping: .fake(),
            paymentSyncDate: .fake(),
            paymentSyncMonth: .fake()
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
extension Networking.ProductTaxStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductTaxStatus {
        .taxable
    }
}
extension Networking.ProductType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductType {
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
            globalUniqueID: .fake(),
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
extension Networking.ProductsReportItem {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ProductsReportItem {
        .init(
            productID: .fake(),
            productName: .fake(),
            quantity: .fake(),
            total: .fake(),
            imageUrl: .fake()
        )
    }
}
extension Networking.Receipt {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.Receipt {
        .init(
            receiptURL: .fake(),
            expirationDate: .fake()
        )
    }
}
extension Networking.RemoteReaderLocation {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.RemoteReaderLocation {
        .init(
            locationID: .fake(),
            city: .fake(),
            country: .fake(),
            addressLine1: .fake(),
            addressLine2: .fake(),
            postalCode: .fake(),
            stateProvinceRegion: .fake(),
            displayName: .fake(),
            liveMode: .fake()
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
            lastSelectedPackageID: .fake(),
            lastOrderCompleted: .fake(),
            addPaymentMethodURL: .fake()
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
extension Networking.ShippingLabelAddressVerification.ShipType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelAddressVerification.ShipType {
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
extension Networking.ShippingLabelCustomsForm.ContentsType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelCustomsForm.ContentsType {
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
extension Networking.ShippingLabelCustomsForm.NonDeliveryOption {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelCustomsForm.NonDeliveryOption {
        .`return`
    }
}
extension Networking.ShippingLabelCustomsForm.RestrictionType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelCustomsForm.RestrictionType {
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
            hazmatCategory: .fake(),
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
extension Networking.ShippingLabelPaperSize {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelPaperSize {
        .a4
    }
}
extension Networking.ShippingLabelPaymentCardType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.ShippingLabelPaymentCardType {
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
            productNames: .fake(),
            shipmentID: .fake(),
            refund: .fake()
        )
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
extension Networking.SiteAPI {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.SiteAPI {
        .init(
            siteID: .fake(),
            namespaces: .fake(),
            applicationPasswordAvailable: .fake()
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
extension Networking.SitePluginStatusEnum {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.SitePluginStatusEnum {
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
extension Networking.SiteSettingGroup {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.SiteSettingGroup {
        .general
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
extension Networking.StoredProductSettings {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.StoredProductSettings {
        .init(
            settings: .fake()
        )
    }
}
extension Networking.StoredProductSettings.Setting {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.StoredProductSettings.Setting {
        .init(
            siteID: .fake(),
            sort: .fake(),
            stockStatusFilter: .fake(),
            productStatusFilter: .fake(),
            productTypeFilter: .fake(),
            productCategoryFilter: .fake(),
            favoriteProduct: .fake()
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
extension Networking.SubscriptionPeriod {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.SubscriptionPeriod {
        .day
    }
}
extension Networking.SubscriptionStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.SubscriptionStatus {
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
extension Networking.TaxRate {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.TaxRate {
        .init(
            id: .fake(),
            siteID: .fake(),
            name: .fake(),
            country: .fake(),
            state: .fake(),
            postcode: .fake(),
            postcodes: .fake(),
            priority: .fake(),
            rate: .fake(),
            order: .fake(),
            taxRateClass: .fake(),
            shipping: .fake(),
            compound: .fake(),
            city: .fake(),
            cities: .fake()
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
            mimeType: .fake(),
            altText: .fake()
        )
    }
}
extension Networking.WCAnalyticsCustomer {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WCAnalyticsCustomer {
        .init(
            siteID: .fake(),
            customerID: .fake(),
            userID: .fake(),
            name: .fake(),
            email: .fake(),
            username: .fake(),
            dateRegistered: .fake(),
            dateLastActive: .fake(),
            ordersCount: .fake(),
            totalSpend: .fake(),
            averageOrderValue: .fake(),
            country: .fake(),
            region: .fake(),
            city: .fake(),
            postcode: .fake()
        )
    }
}
extension Networking.WCPayAccountStatusEnum {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WCPayAccountStatusEnum {
        .complete
    }
}
extension Networking.WCPayCardBrand {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WCPayCardBrand {
        .amex
    }
}
extension Networking.WCPayCardFunding {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WCPayCardFunding {
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
extension Networking.WCPayChargeStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WCPayChargeStatus {
        .succeeded
    }
}
extension Networking.WCPayPaymentIntentStatusEnum {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WCPayPaymentIntentStatusEnum {
        .requiresPaymentMethod
    }
}
extension Networking.WCPayPaymentMethodDetails {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WCPayPaymentMethodDetails {
        .unknown
    }
}
extension Networking.WCPayPaymentMethodType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WCPayPaymentMethodType {
        .card
    }
}
extension Networking.WooPaymentsAccountPayoutSummary {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooPaymentsAccountPayoutSummary {
        .init(
            payoutsEnabled: .fake(),
            payoutsBlocked: .fake(),
            payoutsSchedule: .fake(),
            defaultCurrency: .fake()
        )
    }
}
extension Networking.WooPaymentsBalance {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooPaymentsBalance {
        .init(
            amount: .fake(),
            currency: .fake()
        )
    }
}
extension Networking.WooPaymentsCurrencyBalances {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooPaymentsCurrencyBalances {
        .init(
            pending: .fake(),
            available: .fake(),
            instant: .fake()
        )
    }
}
extension Networking.WooPaymentsCurrencyPayouts {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooPaymentsCurrencyPayouts {
        .init(
            lastPaid: .fake(),
            lastManualPayouts: .fake()
        )
    }
}
extension Networking.WooPaymentsManualPayout {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooPaymentsManualPayout {
        .init(
            currency: .fake(),
            date: .fake()
        )
    }
}
extension Networking.WooPaymentsPayout {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooPaymentsPayout {
        .init(
            id: .fake(),
            date: .fake(),
            type: .fake(),
            amount: .fake(),
            status: .fake(),
            bankAccount: .fake(),
            currency: .fake(),
            automatic: .fake(),
            fee: .fake(),
            feePercentage: .fake(),
            created: .fake()
        )
    }
}
extension Networking.WooPaymentsPayoutInterval {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooPaymentsPayoutInterval {
        .daily
    }
}
extension Networking.WooPaymentsPayoutStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooPaymentsPayoutStatus {
        .estimated
    }
}
extension Networking.WooPaymentsPayoutType {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooPaymentsPayoutType {
        .withdrawal
    }
}
extension Networking.WooPaymentsPayoutsOverview {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooPaymentsPayoutsOverview {
        .init(
            deposit: .fake(),
            balance: .fake(),
            account: .fake()
        )
    }
}
extension Networking.WooPaymentsPayoutsSchedule {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooPaymentsPayoutsSchedule {
        .init(
            delayDays: .fake(),
            interval: .fake()
        )
    }
}
extension Networking.WooShippingAccountSettings {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooShippingAccountSettings {
        .init(
            storeOptions: .fake(),
            accountSettings: .fake()
        )
    }
}
extension Networking.WooShippingAddress {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooShippingAddress {
        .init(
            company: .fake(),
            name: .fake(),
            email: .fake(),
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
extension Networking.WooShippingCarrierPredefinedOptions {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooShippingCarrierPredefinedOptions {
        .init(
            carrierID: .fake(),
            predefinedOptions: .fake()
        )
    }
}
extension Networking.WooShippingConfig {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooShippingConfig {
        .init(
            siteID: .fake(),
            shipments: .fake(),
            shippingLabelData: .fake()
        )
    }
}
extension Networking.WooShippingConfigResponse {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooShippingConfigResponse {
        .init(
            config: .fake()
        )
    }
}
extension Networking.WooShippingCreatePackageResponse {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooShippingCreatePackageResponse {
        .init(
            customPackages: .fake(),
            predefinedOptions: .fake()
        )
    }
}
extension Networking.WooShippingCustomPackage {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooShippingCustomPackage {
        .init(
            id: .fake(),
            name: .fake(),
            rawType: .fake(),
            dimensions: .fake(),
            boxWeight: .fake()
        )
    }
}
extension Networking.WooShippingDestinationAddress {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooShippingDestinationAddress {
        .init(
            company: .fake(),
            address1: .fake(),
            address2: .fake(),
            city: .fake(),
            state: .fake(),
            postcode: .fake(),
            country: .fake(),
            phone: .fake(),
            name: .fake(),
            firstName: .fake(),
            lastName: .fake(),
            email: .fake()
        )
    }
}
extension Networking.WooShippingNormalizedAddress {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooShippingNormalizedAddress {
        .init(
            company: .fake(),
            firstName: .fake(),
            lastName: .fake(),
            email: .fake(),
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
extension Networking.WooShippingOriginAddress {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooShippingOriginAddress {
        .init(
            siteID: .fake(),
            id: .fake(),
            company: .fake(),
            address1: .fake(),
            address2: .fake(),
            city: .fake(),
            state: .fake(),
            postcode: .fake(),
            country: .fake(),
            phone: .fake(),
            firstName: .fake(),
            lastName: .fake(),
            email: .fake(),
            defaultAddress: .fake(),
            isVerified: .fake()
        )
    }
}
extension Networking.WooShippingPackagePurchase {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooShippingPackagePurchase {
        .init(
            shipmentID: .fake(),
            package: .fake(),
            selectedRate: .fake(),
            productIDs: .fake()
        )
    }
}
extension Networking.WooShippingPackagesResponse {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooShippingPackagesResponse {
        .init(
            siteID: .fake(),
            customPackages: .fake(),
            savedPredefinedPackages: .fake(),
            allPredefinedOptions: .fake()
        )
    }
}
extension Networking.WooShippingPredefinedOption {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooShippingPredefinedOption {
        .init(
            title: .fake(),
            providerID: .fake(),
            predefinedPackages: .fake()
        )
    }
}
extension Networking.WooShippingPredefinedPackage {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooShippingPredefinedPackage {
        .init(
            id: .fake(),
            name: .fake(),
            isLetter: .fake(),
            dimensions: .fake(),
            boxWeight: .fake(),
            groupId: .fake()
        )
    }
}
extension Networking.WooShippingPredefinedSavedOption {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooShippingPredefinedSavedOption {
        .init(
            id: .fake(),
            predefinedPackageIDs: .fake()
        )
    }
}
extension Networking.WooShippingSavedPredefinedPackage {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooShippingSavedPredefinedPackage {
        .init(
            groupTitle: .fake(),
            providerID: .fake(),
            package: .fake()
        )
    }
}
extension Networking.WooShippingSelectedRate {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooShippingSelectedRate {
        .init(
            rate: .fake(),
            signatureRate: .fake(),
            adultSignatureRate: .fake(),
            carbonNeutralRate: .fake(),
            saturdayDeliveryRate: .fake(),
            additionalHandlingRate: .fake()
        )
    }
}
extension Networking.WooShippingShipment {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooShippingShipment {
        .init(
            siteID: .fake(),
            orderID: .fake(),
            index: .fake(),
            items: .fake(),
            shippingLabel: .fake()
        )
    }
}
extension Networking.WooShippingShipmentItem {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooShippingShipmentItem {
        .init(
            id: .fake(),
            subItems: .fake()
        )
    }
}
extension Networking.WooShippingUpdateShipment {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooShippingUpdateShipment {
        .init(
            shipmentIdsToUpdate: .fake(),
            shipments: .fake()
        )
    }
}
extension Networking.WooShippingUpdateShipmentResponse {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WooShippingUpdateShipmentResponse {
        .init(
            shipments: .fake()
        )
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
extension Networking.WordPressPage {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WordPressPage {
        .init(
            id: .fake(),
            title: .fake(),
            link: .fake()
        )
    }
}
extension Networking.WordPressTheme {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Networking.WordPressTheme {
        .init(
            id: .fake(),
            description: .fake(),
            name: .fake(),
            demoURI: .fake()
        )
    }
}

// swiftlint:enable line_length
