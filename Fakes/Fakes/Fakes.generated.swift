// Generated using Sourcery 1.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import Networking

extension APNSDevice {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> APNSDevice {
        .init(
            token: .fake(),
            model: .fake(),
            name: .fake(),
            iOSVersion: .fake(),
            identifierForVendor: .fake()
        )
    }
}
extension Account {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Account {
        .init(
            userID: .fake(),
            displayName: .fake(),
            email: .fake(),
            username: .fake(),
            gravatarUrl: .fake()
        )
    }
}
extension AccountSettings {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> AccountSettings {
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
extension AddOnGroup {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> AddOnGroup {
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
extension Address {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Address {
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
extension Country {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Country {
        .init(
            code: .fake(),
            name: .fake(),
            states: .fake()
        )
    }
}
extension CreateProductVariation {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> CreateProductVariation {
        .init(
            regularPrice: .fake(),
            attributes: .fake()
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
extension Leaderboard {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Leaderboard {
        .init(
            id: .fake(),
            label: .fake(),
            rows: .fake()
        )
    }
}
extension Media {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Media {
        .init(
            mediaID: .fake(),
            date: .fake(),
            fileExtension: .fake(),
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
extension Note {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Note {
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
extension NoteBlock {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NoteBlock {
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
extension NoteMedia {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NoteMedia {
        .init(
            type: .fake(),
            range: .fake(),
            url: .fake(),
            size: .fake()
        )
    }
}
extension NoteRange {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> NoteRange {
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
extension Order {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Order {
        .init(
            siteID: .fake(),
            orderID: .fake(),
            parentID: .fake(),
            customerID: .fake(),
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
            items: .fake(),
            billingAddress: .fake(),
            shippingAddress: .fake(),
            shippingLines: .fake(),
            coupons: .fake(),
            refunds: .fake(),
            fees: .fake()
        )
    }
}
extension OrderCouponLine {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> OrderCouponLine {
        .init(
            couponID: .fake(),
            code: .fake(),
            discount: .fake(),
            discountTax: .fake()
        )
    }
}
extension OrderFeeLine {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> OrderFeeLine {
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
extension OrderItem {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> OrderItem {
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
            attributes: .fake()
        )
    }
}
extension OrderItemAttribute {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> OrderItemAttribute {
        .init(
            metaID: .fake(),
            name: .fake(),
            value: .fake()
        )
    }
}
extension OrderItemRefund {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> OrderItemRefund {
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
            totalTax: .fake()
        )
    }
}
extension OrderItemTax {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> OrderItemTax {
        .init(
            taxID: .fake(),
            subtotal: .fake(),
            total: .fake()
        )
    }
}
extension OrderItemTaxRefund {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> OrderItemTaxRefund {
        .init(
            taxID: .fake(),
            subtotal: .fake(),
            total: .fake()
        )
    }
}
extension OrderNote {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> OrderNote {
        .init(
            noteID: .fake(),
            dateCreated: .fake(),
            note: .fake(),
            isCustomerNote: .fake(),
            author: .fake()
        )
    }
}
extension OrderRefundCondensed {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> OrderRefundCondensed {
        .init(
            refundID: .fake(),
            reason: .fake(),
            total: .fake()
        )
    }
}
extension OrderStatsV4 {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> OrderStatsV4 {
        .init(
            siteID: .fake(),
            granularity: .fake(),
            totals: .fake(),
            intervals: .fake()
        )
    }
}
extension OrderStatsV4Interval {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> OrderStatsV4Interval {
        .init(
            interval: .fake(),
            dateStart: .fake(),
            dateEnd: .fake(),
            subtotals: .fake()
        )
    }
}
extension OrderStatsV4Totals {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> OrderStatsV4Totals {
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
            totalProducts: .fake()
        )
    }
}
extension OrderStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> OrderStatus {
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
        .pending
    }
}
extension PaymentGateway {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> PaymentGateway {
        .init(
            siteID: .fake(),
            gatewayID: .fake(),
            title: .fake(),
            description: .fake(),
            enabled: .fake(),
            features: .fake()
        )
    }
}
extension Post {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Post {
        .init(
            siteID: .fake(),
            password: .fake()
        )
    }
}
extension Product {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Product {
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
            addOns: .fake()
        )
    }
}
extension ProductAddOn {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductAddOn {
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
extension ProductAddOnOption {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductAddOnOption {
        .init(
            label: .fake(),
            price: .fake(),
            priceType: .fake(),
            imageID: .fake()
        )
    }
}
extension ProductAttribute {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductAttribute {
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
extension ProductAttributeTerm {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductAttributeTerm {
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
extension ProductCatalogVisibility {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductCatalogVisibility {
        .visible
    }
}
extension ProductCategory {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductCategory {
        .init(
            categoryID: .fake(),
            siteID: .fake(),
            parentID: .fake(),
            name: .fake(),
            slug: .fake()
        )
    }
}
extension ProductDefaultAttribute {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductDefaultAttribute {
        .init(
            attributeID: .fake(),
            name: .fake(),
            option: .fake()
        )
    }
}
extension ProductDimensions {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductDimensions {
        .init(
            length: .fake(),
            width: .fake(),
            height: .fake()
        )
    }
}
extension ProductDownload {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductDownload {
        .init(
            downloadID: .fake(),
            name: .fake(),
            fileURL: .fake()
        )
    }
}
extension ProductDownloadDragAndDrop {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductDownloadDragAndDrop {
        .init(
            downloadableFile: .fake()
        )
    }
}
extension ProductImage {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductImage {
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
extension ProductReview {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductReview {
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
extension ProductShippingClass {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductShippingClass {
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
        .publish
    }
}
extension ProductStockStatus {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductStockStatus {
        .inStock
    }
}
extension ProductTag {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductTag {
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
extension ProductVariation {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductVariation {
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
            menuOrder: .fake()
        )
    }
}
extension ProductVariationAttribute {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductVariationAttribute {
        .init(
            id: .fake(),
            name: .fake(),
            option: .fake()
        )
    }
}
extension Refund {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Refund {
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
extension ShipmentTracking {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShipmentTracking {
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
extension ShipmentTrackingProvider {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShipmentTrackingProvider {
        .init(
            siteID: .fake(),
            name: .fake(),
            url: .fake()
        )
    }
}
extension ShipmentTrackingProviderGroup {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShipmentTrackingProviderGroup {
        .init(
            name: .fake(),
            siteID: .fake(),
            providers: .fake()
        )
    }
}
extension ShippingLabel {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabel {
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
            productNames: .fake()
        )
    }
}
extension ShippingLabelAccountSettings {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelAccountSettings {
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
extension ShippingLabelAddress {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelAddress {
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
extension ShippingLabelAddressValidationError {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelAddressValidationError {
        .init(
            addressError: .fake(),
            generalError: .fake()
        )
    }
}
extension ShippingLabelAddressValidationSuccess {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelAddressValidationSuccess {
        .init(
            address: .fake(),
            isTrivialNormalization: .fake()
        )
    }
}
extension ShippingLabelAddressVerification {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelAddressVerification {
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
extension ShippingLabelCarrierRate {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelCarrierRate {
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
extension ShippingLabelCreationEligibilityResponse {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelCreationEligibilityResponse {
        .init(
            isEligible: .fake(),
            reason: .fake()
        )
    }
}
extension ShippingLabelCustomPackage {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelCustomPackage {
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
extension ShippingLabelPackagePurchase {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelPackagePurchase {
        .init(
            package: .fake(),
            rate: .fake(),
            productIDs: .fake()
        )
    }
}
extension ShippingLabelPackageSelected {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelPackageSelected {
        .init(
            boxID: .fake(),
            length: .fake(),
            width: .fake(),
            height: .fake(),
            weight: .fake(),
            isLetter: .fake()
        )
    }
}
extension ShippingLabelPackagesResponse {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelPackagesResponse {
        .init(
            storeOptions: .fake(),
            customPackages: .fake(),
            predefinedOptions: .fake()
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
extension ShippingLabelPaymentMethod {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelPaymentMethod {
        .init(
            paymentMethodID: .fake(),
            name: .fake(),
            cardType: .fake(),
            cardDigits: .fake(),
            expiry: .fake()
        )
    }
}
extension ShippingLabelPredefinedOption {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelPredefinedOption {
        .init(
            title: .fake(),
            predefinedPackages: .fake()
        )
    }
}
extension ShippingLabelPredefinedPackage {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelPredefinedPackage {
        .init(
            id: .fake(),
            title: .fake(),
            isLetter: .fake(),
            dimensions: .fake()
        )
    }
}
extension ShippingLabelPrintData {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelPrintData {
        .init(
            mimeType: .fake(),
            base64Content: .fake()
        )
    }
}
extension ShippingLabelPurchase {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelPurchase {
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
extension ShippingLabelRefund {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelRefund {
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
extension ShippingLabelSettings {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelSettings {
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
extension ShippingLabelStoreOptions {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLabelStoreOptions {
        .init(
            currencySymbol: .fake(),
            dimensionUnit: .fake(),
            weightUnit: .fake(),
            originCountry: .fake()
        )
    }
}
extension ShippingLine {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLine {
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
extension ShippingLineTax {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ShippingLineTax {
        .init(
            taxID: .fake(),
            subtotal: .fake(),
            total: .fake()
        )
    }
}
extension Site {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> Site {
        .init(
            siteID: .fake(),
            name: .fake(),
            description: .fake(),
            url: .fake(),
            plan: .fake(),
            isWooCommerceActive: .fake(),
            isWordPressStore: .fake(),
            timezone: .fake(),
            gmtOffset: .fake()
        )
    }
}
extension SiteAPI {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> SiteAPI {
        .init(
            siteID: .fake(),
            namespaces: .fake()
        )
    }
}
extension SitePlan {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> SitePlan {
        .init(
            siteID: .fake(),
            shortName: .fake()
        )
    }
}
extension SitePlugin {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> SitePlugin {
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
extension SiteSetting {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> SiteSetting {
        .init(
            siteID: .fake(),
            settingID: .fake(),
            label: .fake(),
            description: .fake(),
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
extension SiteVisitStats {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> SiteVisitStats {
        .init(
            siteID: .fake(),
            date: .fake(),
            granularity: .fake(),
            items: .fake()
        )
    }
}
extension SiteVisitStatsItem {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> SiteVisitStatsItem {
        .init(
            period: .fake(),
            visitors: .fake()
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
extension StateOfACountry {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> StateOfACountry {
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
extension StoredProductSettings {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> StoredProductSettings {
        .init(
            settings: .fake()
        )
    }
}
extension SystemPlugin {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> SystemPlugin {
        .init(
            siteID: .fake(),
            plugin: .fake(),
            name: .fake(),
            version: .fake(),
            versionLatest: .fake(),
            url: .fake(),
            authorName: .fake(),
            authorUrl: .fake(),
            networkActivated: .fake()
        )
    }
}
extension TaxClass {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> TaxClass {
        .init(
            siteID: .fake(),
            name: .fake(),
            slug: .fake()
        )
    }
}
extension TopEarnerStats {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> TopEarnerStats {
        .init(
            siteID: .fake(),
            date: .fake(),
            granularity: .fake(),
            limit: .fake(),
            items: .fake()
        )
    }
}
extension TopEarnerStatsItem {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> TopEarnerStatsItem {
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
extension UploadableMedia {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> UploadableMedia {
        .init(
            localURL: .fake(),
            filename: .fake(),
            mimeType: .fake()
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
extension WCPayPaymentIntentStatusEnum {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> WCPayPaymentIntentStatusEnum {
        .requiresPaymentMethod
    }
}
