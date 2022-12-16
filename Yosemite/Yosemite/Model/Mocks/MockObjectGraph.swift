import Foundation
import Storage
import Hardware

public protocol MockObjectGraph {
    var userCredentials: WPCOMCredentials { get }
    var defaultAccount: Account { get }
    var defaultSite: Site { get }
    var defaultSiteAPI: SiteAPI { get }

    var sites: [Site] { get }
    var siteSettings: [SiteSetting] { get }
    var systemPlugins: [SystemPlugin] { get }
    var paymentGatewayAccounts: [PaymentGatewayAccount] { get }
    var cardReaders: [CardReader] { get }
    var orders: [Order] { get }
    var products: [Product] { get }
    var reviews: [ProductReview] { get }

    var thisMonthOrderStats: OrderStatsV4 { get }
    var thisMonthVisitStats: SiteVisitStats { get }
    var thisMonthTopProducts: TopEarnerStats { get }

    func accountWithId(id: Int64) -> Account
    func accountSettingsWithUserId(userId: Int64) -> AccountSettings

    func siteWithId(id: Int64) -> Site

    var currentNotificationCount: Int { get }
    var statsVersion: StatsVersion { get }

    func statsV4ShouldBeAvailable(forSiteId: Int64) -> Bool
}

let mockResourceUrlHost = "http://localhost:\(UserDefaults.standard.integer(forKey: "mocks-port"))/"

// MARK: SiteSetting Accessors
extension MockObjectGraph {
    func siteSettings(for siteID: Int64) -> [SiteSetting] {
        return siteSettings.filter { $0.siteID == siteID }
    }
}

// MARK: SystemPlugin Accessors
extension MockObjectGraph {
    func systemPlugins(for siteID: Int64) -> [SystemPlugin] {
        return systemPlugins.filter { $0.siteID == siteID }
    }
}

// MARK: PaymentGateWayAccount Accessor
extension MockObjectGraph {
    func paymentGatewayAccounts(for siteID: Int64) -> [PaymentGatewayAccount] {
        return paymentGatewayAccounts.filter { $0.siteID == siteID }
    }
}

// MARK: Product Accessors
extension MockObjectGraph {

    func product(forSiteId siteId: Int64, productId: Int64) -> Product {
        return products(forSiteId: siteId).first { $0.productID == productId }!
    }

    func products(forSiteId siteId: Int64) -> [Product] {
        return products.filter { $0.siteID == siteId }
    }

    func products(forSiteId siteId: Int64, productIds: [Int64]) -> [Product] {
        return products(forSiteId: siteId).filter { productIds.contains($0.productID) }
    }

    func products(forSiteId siteId: Int64, without productIDs: [Int64]) -> [Product] {
        return products(forSiteId: siteId).filter { !productIDs.contains($0.productID) }
    }
}

// MARK: Order Accessors
extension MockObjectGraph {

    func order(forSiteId siteId: Int64, orderId: Int64) -> Order? {
        return orders(forSiteId: siteId).first { $0.orderID == orderId }
    }

    func orders(forSiteId siteId: Int64) -> [Order] {
        return orders.filter { $0.siteID == siteId }
    }

    func orders(withStatus status: OrderStatusEnum, forSiteId siteId: Int64) -> [Order] {
        return orders(forSiteId: siteId).filter { $0.status == status }
    }
}

// MARK: ProductReview Accessors
extension MockObjectGraph {

    func review(forSiteId siteId: Int64, reviewId: Int64) -> ProductReview? {
        reviews(forSiteId: siteId).first { $0.reviewID == reviewId }
    }

    func reviews(forSiteId siteId: Int64) -> [ProductReview] {
        reviews.filter { $0.siteID == siteId }
    }
}

// MARK: SiteSetting Creation Helper
extension MockObjectGraph {
    static func createSiteSetting(siteID: Int64 = 1,
                                  settingID: String,
                                  label: String,
                                  settingDescription: String,
                                  value: String,
                                  settingGroupKey: String) -> SiteSetting {
        SiteSetting(siteID: siteID,
                    settingID: settingID,
                    label: label,
                    settingDescription: settingDescription,
                    value: value,
                    settingGroupKey: settingGroupKey)
    }
}

// MARK: SystemPlugin Creation Helper
extension MockObjectGraph {
    static func createSystemPlugin(siteID: Int64 = 1,
                                   plugin: String,
                                   name: String,
                                   version: String,
                                   versionLatest: String = "",
                                   url: String = "",
                                   authorName: String = "",
                                   authorUrl: String = "",
                                   networkActivated: Bool = true,
                                   active: Bool = true) -> SystemPlugin {
        SystemPlugin(siteID: siteID,
                     plugin: plugin,
                     name: name,
                     version: version,
                     versionLatest: versionLatest,
                     url: url,
                     authorName: authorName,
                     authorUrl: authorUrl,
                     networkActivated: networkActivated,
                     active: active)
    }
}

// MARK: PaymentGatewayAccount Creation Helper
extension MockObjectGraph {
    static func createPaymentGatewayAccount(gatewayID: String = WCPayAccount.gatewayID,
                                            status: WCPayAccountStatusEnum = .complete,
                                            hasPendingRequirements: Bool = false,
                                            hasOverdueRequirements: Bool = false,
                                            currentDeadline: Date? = nil,
                                            statementDescriptor: String = "",
                                            defaultCurrency: String = "USD",
                                            supportedCurrencies: [String] = ["US", "CA"],
                                            country: String = "US",
                                            isCardPresentEligible: Bool = true,
                                            isLive: Bool = false,
                                            isInTestMode: Bool = false) -> PaymentGatewayAccount {
        PaymentGatewayAccount(
            siteID: 1,
            gatewayID: WCPayAccount.gatewayID,
            status: status.rawValue,
            hasPendingRequirements: hasPendingRequirements,
            hasOverdueRequirements: hasOverdueRequirements,
            currentDeadline: currentDeadline,
            statementDescriptor: statementDescriptor,
            defaultCurrency: defaultCurrency,
            supportedCurrencies: supportedCurrencies,
            country: country,
            isCardPresentEligible: isCardPresentEligible,
            isLive: isLive,
            isInTestMode: isInTestMode
        )
    }
}

// MARK: CardReader Creation Helper
extension MockObjectGraph {
    static func createCardReader() -> CardReader {
        CardReader(serial: "WPE-SIMULATOR-1",
                   vendorIdentifier: "SIMULATOR",
                   name: "Simulated POS E",
                   status: .init(connected: true, remembered: true),
                   softwareVersion: "1.00.03.34-SZZZ_Generic_v45-300001",
                   batteryLevel: 0.5,
                   readerType: .chipper,
                   locationId: "st_simulated")
    }
}

// MARK: Product => OrderItem Transformer
let priceFormatter = NumberFormatter()

extension MockObjectGraph {

    static func createOrderItem(from product: Product, count: Decimal) -> OrderItem {

        let price = priceFormatter.number(from: product.price)!.decimalValue as NSDecimalNumber
        let total = priceFormatter.number(from: product.price)!.decimalValue * count

        return OrderItem(
            itemID: 0,
            name: product.name,
            productID: product.productID,
            variationID: 0,
            quantity: count,
            price: price,
            sku: nil,
            subtotal: "\(total)",
            subtotalTax: "",
            taxClass: "",
            taxes: [],
            total: "\(total)",
            totalTax: "0",
            attributes: []
        )
    }
}

// MARK: Product Creation Helper
extension MockObjectGraph {
    static func createProduct(
        name: String,
        price: Decimal,
        salePrice: Decimal? = nil,
        quantity: Decimal,
        siteId: Int64 = 1,
        image: ProductImage? = nil
    ) -> Product {

        let productId = ProductId.next

        let defaultImage = ProductImage(
            imageID: productId,
            dateCreated: Date(),
            dateModified: nil,
            src: mockResourceUrlHost + name.slugified!,
            name: name,
            alt: name
        )

        let images = image != nil ? [image!] : [defaultImage]

        return Product(
            siteID: siteId,
            productID: productId,
            name: name,
            slug: name.slugified!,
            permalink: "",
            date: Date(),
            dateCreated: Date(),
            dateModified: nil,
            dateOnSaleStart: nil,
            dateOnSaleEnd: nil,
            productTypeKey: "",
            statusKey: "",
            featured: true,
            catalogVisibilityKey: "",
            fullDescription: nil,
            shortDescription: nil,
            sku: nil,
            price: priceFormatter.string(from: price as NSNumber)!,
            regularPrice: nil,
            salePrice: salePrice == nil ? nil : priceFormatter.string(from: salePrice! as NSNumber)!,
            onSale: salePrice != nil,
            purchasable: true,
            totalSales: 99,
            virtual: false,
            downloadable: false,
            downloads: [],
            downloadLimit: 0,
            downloadExpiry: 0,
            buttonText: "Buy",
            externalURL: nil,
            taxStatusKey: "foo",
            taxClass: nil,
            manageStock: true,
            stockQuantity: quantity,
            stockStatusKey: ProductStockStatus.from(quantity: quantity).rawValue,
            backordersKey: "",
            backordersAllowed: true,
            backordered: quantity < 0,
            soldIndividually: true,
            weight: "20 grams",
            dimensions: .init(length: "10", width: "10", height: "10"),
            shippingRequired: true,
            shippingTaxable: true,
            shippingClass: "",
            shippingClassID: 0,
            productShippingClass: .none,
            reviewsAllowed: true,
            averageRating: "5",
            ratingCount: 64,
            relatedIDs: [],
            upsellIDs: [],
            crossSellIDs: [],
            parentID: 0,
            purchaseNote: nil,
            categories: [],
            tags: [],
            images: images,
            attributes: [],
            defaultAttributes: [],
            variations: [],
            groupedProducts: [],
            menuOrder: 0,
            addOns: []
        )
    }
}

// MARK: Order Creation Helper
extension MockObjectGraph {
    static func createOrder(
        number: Int64,
        customer: MockCustomer,
        status: OrderStatusEnum,
        daysOld: Int = 0,
        total: Decimal,
        needsPayment: Bool = false,
        items: [OrderItem] = []
    ) -> Order {

        Order(
            siteID: 1,
            orderID: number,
            parentID: 0,
            customerID: 1,
            orderKey: "",
            isEditable: false,
            needsPayment: needsPayment,
            needsProcessing: false,
            number: "\(number)",
            status: status,
            currency: "USD",
            customerNote: nil,
            dateCreated: Calendar.current.date(byAdding: .day, value: daysOld * -1, to: Date()) ?? Date(),
            dateModified: Date(),
            datePaid: nil,
            discountTotal: "0",
            discountTax: "0",
            shippingTotal: "0",
            shippingTax: "0",
            total: priceFormatter.string(from: total as NSNumber)!,
            totalTax: "0",
            paymentMethodID: "0",
            paymentMethodTitle: "MasterCard",
            paymentURL: nil,
            chargeID: nil,
            items: items,
            billingAddress: customer.billingAddress,
            shippingAddress: customer.billingAddress,
            shippingLines: [],
            coupons: [],
            refunds: [],
            fees: [],
            taxes: [],
            customFields: []
        )
    }
}

// MARK: ProductReview Creation Helper
extension MockObjectGraph {
    static func createProductReview(
        product: Product,
        customer: MockCustomer,
        daysOld: Int = 0,
        status: ProductReviewStatus,
        text: String,
        rating: Int,
        verified: Bool
    ) -> ProductReview {
        ProductReview(
            siteID: 1,
            reviewID: -1,
            productID: product.productID,
            dateCreated: Date(),
            statusKey: status.rawValue,
            reviewer: customer.fullName,
            reviewerEmail: customer.email ?? customer.defaultEmail,
            reviewerAvatarURL: customer.defaultGravatar,
            review: text,
            rating: rating,
            verified: verified
        )
    }
}

// MARK: Stats Creation Helpers
extension MockObjectGraph {

    static func createMonthlyInterval(
        date: Date,
        orderCount: Int,
        revenue: Decimal
    ) -> OrderStatsV4Interval {
        OrderStatsV4Interval(
            interval: String(date.day),
            dateStart: date.asOrderStatsString,
            dateEnd: date.monthEnd.asOrderStatsString,
            subtotals: createTotal(orderCount: orderCount, revenue: revenue)
        )
    }

    static func createVisitStatsItem(granularity: StatGranularity, periodDate: Date, visitors: Int, views: Int) -> SiteVisitStatsItem {
        switch granularity {
        case .day:
            return SiteVisitStatsItem(period: periodDate.asVisitStatsMonthString, visitors: visitors, views: views)
        default:
            fatalError("Not implemented yet")
        }
    }

    static func createTotal(orderCount: Int, revenue: Decimal) -> OrderStatsV4Totals {
        return OrderStatsV4Totals(
            totalOrders: orderCount,
            totalItemsSold: 0,
            grossRevenue: revenue,
            couponDiscount: 0,
            totalCoupons: 0,
            refunds: 0,
            taxes: 0,
            shipping: 0,
            netRevenue: 0,
            totalProducts: 0,
            averageOrderValue: 0
        )
    }

    static func createStats(
        siteID: Int64,
        granularity: StatsGranularityV4,
        intervals: [OrderStatsV4Interval]
    ) -> OrderStatsV4 {
        OrderStatsV4(
            siteID: siteID,
            granularity: granularity,
            totals: intervals.aggregateTotals,
            intervals: intervals
        )
    }

    static func createVisitStats(siteID: Int64, granularity: StatGranularity, items: [SiteVisitStatsItem]) -> SiteVisitStats {

        switch granularity {
            case .day: preconditionFailure("Not implemented")
            case .week: preconditionFailure("Not implemented")
            case .month:
            return SiteVisitStats(
                siteID: siteID,
                date: Date().asVisitStatsMonthString,
                granularity: .day,
                items: items
            )
            case .year: preconditionFailure("Not implemented")
        }
    }

    static func createStats(siteID: Int64, granularity: StatGranularity, items: [TopEarnerStatsItem]) -> TopEarnerStats {
        TopEarnerStats(
            siteID: siteID,
            date: StatsStoreV4.buildDateString(from: Date(), with: granularity),
            granularity: granularity,
            limit: "",
            items: items
        )
    }

    static func createTopEarningItem(product: Product, quantity: Int, price: Double? = nil) -> TopEarnerStatsItem {

        let averagePrice = price ?? Double(product.price) ?? 100.00

        return TopEarnerStatsItem(
            productID: product.productID,
            productName: product.name,
            quantity: quantity,
            price: averagePrice,
            total: Double(quantity) * averagePrice,
            currency: "USD",
            imageUrl: product.images.first?.src
        )
    }
}

private extension Array where Element == OrderStatsV4Interval {
    var aggregateTotals: OrderStatsV4Totals {

        let totalOrders = self.reduce(0) { $0 + $1.subtotals.totalOrders }
        let totalRevenue = self.reduce(0) { $0 + $1.subtotals.grossRevenue }

        return OrderStatsV4Totals(
            totalOrders: totalOrders,
            totalItemsSold: 0,
            grossRevenue: totalRevenue,
            couponDiscount: 0,
            totalCoupons: 0,
            refunds: 0,
            taxes: 0,
            shipping: 0,
            netRevenue: 0,
            totalProducts: 0,
            averageOrderValue: 0
        )
    }
}

 extension Date {

    func addingYears(_ count: Int) -> Date {
        return NSCalendar.current.date(byAdding: .year, value: count, to: self)!
    }

    func subtracingYears(_ count: Int) -> Date {
        addingYears(count * -1)
    }

    func addingMonths(_ count: Int) -> Date {
        return NSCalendar.current.date(byAdding: .month, value: count, to: self)!
    }

    func subtractingMonths(_ count: Int) -> Date {
        addingMonths(count * -1)
    }

    func addingDays(_ count: Int) -> Date {
        return NSCalendar.current.date(byAdding: .day, value: count, to: self)!
    }

    func subtractingDays(_ count: Int) -> Date {
        addingDays(count * -1)
    }

    var year: Int {
        let components = Calendar.current.dateComponents(in: .current, from: self)
        return components.year ?? 0
    }

    var month: Int {
        let components = Calendar.current.dateComponents(in: .current, from: self)
        return components.month ?? 0
    }

    var day: Int {
        let components = Calendar.current.dateComponents(in: .current, from: self)
        return components.day ?? 0
    }

    var yearStart: Date {
        let year = Calendar.current.component(.year, from: self)
        return Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))!
    }

    var yearEnd: Date {
        let year = Calendar.current.component(.year, from: self)
        return Calendar.current.date(from: DateComponents(year: year, month: 12, day: 31))!
    }

    var monthStart: Date {
        let components = DateComponents(year: self.year, month: self.month, day: 1)
        return Calendar.current.date(from: components)!
    }

    var monthEnd: Date {
        monthStart.addingMonths(1).subtractingDays(1)
    }

    var asVisitStatsMonthString: String {
        return DateFormatter.Stats.statsDayFormatter.string(from: self)
    }

    var asVisitStatsYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-12-31"
        return formatter.string(from: self)
    }

    var asOrderStatsString: String {
        return DateFormatter.Stats.dateTimeFormatter.string(from: self)
    }

    static func from(dateString: String) -> Date {
        return DateFormatter.Stats.statsDayFormatter.date(from: dateString)!
    }
}
