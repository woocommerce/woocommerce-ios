import Foundation
import Storage

struct i18n {
    struct DefaultAccount {
        static let displayName = NSLocalizedString("My Account", comment: "displayName for the screenshot demo account")
        static let email = NSLocalizedString("woocommercestore@example.com", comment: "email address for the screenshot demo account")
        static let username = NSLocalizedString("test account", comment: "username for the screenshot demo account")
    }

    struct DefaultSite {
        static let name = NSLocalizedString("Your WooCommerce Store", comment: "Store Name for the screenshot demo account")
        static let url = NSLocalizedString("example.com", comment: "")
        static let adminURL = NSLocalizedString("example.com/wp-admin", comment: "")
    }
}

struct ScreenshotObjectGraph: MockObjectGraph {

     let userCredentials = Credentials(
        username: i18n.DefaultAccount.username,
        authToken: UUID().uuidString,
        siteAddress: i18n.DefaultSite.url
    )

    let defaultAccount = Account(
        userID: 1,
        displayName: i18n.DefaultAccount.displayName,
        email: i18n.DefaultAccount.email,
        username: i18n.DefaultAccount.username,
        gravatarUrl: nil
    )

    let defaultSite = Site(
        siteID: 1,
        name: i18n.DefaultSite.name,
        description: "",
        url: i18n.DefaultSite.url,
        adminURL: i18n.DefaultSite.adminURL,
        plan: "",
        isJetpackThePluginInstalled: true,
        isJetpackConnected: true,
        isWooCommerceActive: true,
        isWordPressStore: true,
        jetpackConnectionActivePlugins: [],
        timezone: "UTC",
        gmtOffset: 0
    )

    /// May not be needed anymore if we're not mocking the API
    let defaultSiteAPI = SiteAPI(siteID: 1, namespaces: [
        WooAPIVersion.mark3.rawValue,
        WooAPIVersion.mark4.rawValue,
    ])

    var sites: [Site] {
        return [defaultSite]
    }

    var siteSettings: [SiteSetting] = [
        createSiteSetting(settingID: "woocommerce_default_country",
                          label: "Country and State",
                          settingDescription: "The country and state or province, if any, in which your business is located.",
                          value: "US:CA",
                          settingGroupKey: "general")
    ]

    var systemPlugins: [SystemPlugin] = [
        createSystemPlugin(plugin: "woocommerce-payments",
                           name: "WooCommerce Payments",
                           version: "3.2.1")
    ]

    var paymentGatewayAccounts: [PaymentGatewayAccount] = [
        createPaymentGatewayAccount()
    ]

    var cardReaders: [CardReader] = [
        createCardReader()
    ]

    func accountWithId(id: Int64) -> Account {
        return defaultAccount
    }

    func accountSettingsWithUserId(userId: Int64) -> AccountSettings {
        return .init(userID: userId, tracksOptOut: true, firstName: "Mario", lastName: "Rossi")
    }

    var currentNotificationCount: Int = 4
    var statsVersion: StatsVersion = .v4
    func statsV4ShouldBeAvailable(forSiteId: Int64) -> Bool {
        return true // statsV4 for all sites
    }

    func siteWithId(id: Int64) -> Site {
        return defaultSite
    }

    var orders: [Order] = [
        createOrder(
            number: 2201,
            customer: Customers.MiraWorkman,
            status: .processing,
            total: 1310.00,
            items: [
                createOrderItem(from: Products.malayaShades, count: 4),
                createOrderItem(from: Products.blackCoralShades, count: 5),
            ]
        ),
        createOrder(
            number: 2155,
            customer: Customers.LydiaDonin,
            status: .processing,
            daysOld: 3,
            total: 300
        ),
        createOrder(
            number: 2116,
            customer: Customers.ChanceVicarro,
            status: .processing,
            daysOld: 4,
            total: 300
        ),
        createOrder(
            number: 2104,
            customer: Customers.MarcusCurtis,
            status: .processing,
            daysOld: 5,
            total: 420
        ),
        createOrder(
            number: 2087,
            customer: Customers.MollyBloom,
            status: .processing,
            daysOld: 6,
            total: 46.96
        ),
    ]

    var products: [Product] = [
        Products.roseGoldShades,
        Products.coloradoShades,
        Products.blackCoralShades,
        Products.akoyaPearlShades,
        Products.malayaShades,
    ]

    var reviews: [ProductReview] = [
        createProductReview(
            product: Products.blackCoralShades,
            customer: Customers.PaytinLubin,
            status: .hold,
            text: "Travel in style!",
            rating: 5,
            verified: true
        ),
        createProductReview(
            product: Products.blackCoralShades,
            customer: Customers.LydiaDonin,
            status: .hold,
            text: "I love these shades! They are super sturdy and stylish at the same time. I'm planning to buy more of them!",
            rating: 5,
            verified: false
        ),
        createProductReview(
            product: Products.blackCoralShades,
            customer: Customers.MiraWorkman,
            status: .hold,
            text: "Can't go outside without them anymore!",
            rating: 5,
            verified: false
        ),
        createProductReview(
            product: Products.akoyaPearlShades,
            customer: Customers.MarcusCurtis,
            status: .approved,
            text: "Such a great product!",
            rating: 4,
            verified: true
        ),
        createProductReview(
            product: Products.coloradoShades,
            customer: Customers.LucyLiu,
            status: .approved,
            text: "Great UV protection, I've dropped them a few times and they are still holding up perfectly",
            rating: 5,
            verified: true
        ),
        createProductReview(
            product: Products.roseGoldShades,
            customer: Customers.JaneCheng,
            status: .approved,
            text: "I love these shades! They are super sturdy and stylish at the same time. I’m planning to buy them again for a birthday gift next month.",
            rating: 5,
            verified: true
        ),
        createProductReview(
            product: Products.roseGoldShades,
            customer: Customers.ChanceVicarro,
            status: .approved,
            text: "The best I've ever worn",
            rating: 4,
            verified: true
        )
    ]

    var thisMonthVisitStats: SiteVisitStats {
        Self.createVisitStats(
            siteID: 1,
            granularity: .month,
            items: [Int](0..<30).map { dayIndex in
                Self.createVisitStatsItem(
                    granularity: .day,
                    periodDate: date.monthStart.addingDays(dayIndex),
                    visitors: Int.random(in: 0 ... 20)
                )
            }
        )
    }

    var thisMonthTopProducts: TopEarnerStats = createStats(siteID: 1, granularity: .month, items: [
        createTopEarningItem(product: Products.akoyaPearlShades, quantity: 17),
        createTopEarningItem(product: Products.blackCoralShades, quantity: 11),
        createTopEarningItem(product: Products.coloradoShades, quantity: 5),
    ])

    var thisYearVisitStats: SiteVisitStats {
        Self.createVisitStats(
            siteID: 1,
            granularity: .year,
            items: [Int](0..<12).map { monthIndex in
                Self.createVisitStatsItem(
                    granularity: .month,
                    periodDate: date.yearStart.addingMonths(monthIndex),
                    visitors: Int.random(in: 100 ... 500)
                )
            }
        )
    }

    var thisYearTopProducts: TopEarnerStats = createStats(siteID: 1, granularity: .year, items: [
        createTopEarningItem(product: Products.akoyaPearlShades, quantity: 17),
        createTopEarningItem(product: Products.blackCoralShades, quantity: 11),
        createTopEarningItem(product: Products.coloradoShades, quantity: 5),
    ])

    /// The probability of a sale for each visit when generating random stats
    ///
    private let orderProbabilityRange = 0.1...0.5

    /// The possible value of an order when generating random stats
    ///
    private let orderValueRange = 5 ..< 20

    var thisMonthOrderStats: OrderStatsV4 {
        Self.createStats(
            siteID: 1,
            granularity: .monthly,
            intervals: thisMonthVisitStats.items!.enumerated().map {
                Self.createMonthlyInterval(
                    date: date.monthStart.addingDays($0.offset),
                    orderCount: Int(Double($0.element.visitors) * Double.random(in: orderProbabilityRange)),
                    revenue: Decimal($0.element.visitors) * Decimal.random(in: orderValueRange)
                )
            }
        )
    }

    var thisYearOrderStats: OrderStatsV4 {
        Self.createStats(
            siteID: 1,
            granularity: .yearly,
            intervals: thisYearVisitStats.items!.enumerated().map {
                Self.createYearlyInterval(
                    date: date.yearStart.addingMonths($0.offset),
                    orderCount: Int(Double($0.element.visitors) * Double.random(in: orderProbabilityRange)),
                    revenue: Decimal($0.element.visitors) * Decimal.random(in: orderValueRange)
                )
            }
        )
    }

    private let date: Date

    init(date: Date = .init()) {
        self.date = date
    }
}

extension ScreenshotObjectGraph {
    struct Customers {
        static let MiraWorkman = MockCustomer(
            firstName: "Mira",
            lastName: "Workman",
            company: nil,
            address1: "123 Main Street",
            address2: nil,
            city: "San Francisco",
            state: "CA",
            postCode: "94119",
            country: "US",
            phone: nil,
            email: nil
        )

        static let LydiaDonin = MockCustomer(
            firstName: "Lydia",
            lastName: "Donin"
        )

        static let ChanceVicarro = MockCustomer(
            firstName: "Chance",
            lastName: "Vacarro"
        )

        static let MarcusCurtis = MockCustomer(
            firstName: "Marcus",
            lastName: "Curtis"
        )

        static let MollyBloom = MockCustomer(
            firstName: "Molly",
            lastName: "Bloom"
        )

        static let PaytinLubin = MockCustomer(
            firstName: "Paytin",
            lastName: "Lubin"
        )

        static let LucyLiu = MockCustomer(
            firstName: "Lucy",
            lastName: "Liu"
        )

        static let JaneCheng = MockCustomer(
            firstName: "Jane",
            lastName: "Cheng"
        )
    }

    struct Products {
        static let roseGoldShades = createProduct(
            name: "Rose Gold Shades",
            price: 199.0,
            quantity: 0,
            image: ProductImage.fromUrl("https://automatticwidgets.com/wp-content/uploads/2020/01/annie-theby-FlP6C5pkMKs-unsplash.png")
        )

        static let blackCoralShades = createProduct(
            name: "Black Coral Shades",
            price: 150.00,
            quantity: -24
        )

        static let malayaShades = createProduct(
            name: "Malaya Shades",
            price: 140.00,
            quantity: 17
        )

        static let coloradoShades = createProduct(
            name: "Colorado shades",
            price: 135,
            salePrice: 100,
            quantity: 98
        )

        static let akoyaPearlShades = createProduct(
            name: "Akoya Pearl shades",
            price: 110,
            quantity: 23
        )
    }
}

extension Decimal {
    static func random(in range: Range<Int>) -> Decimal {
        let lowerBound = NSDecimalNumber(value: range.lowerBound).doubleValue
        let upperBound = NSDecimalNumber(value: range.upperBound).doubleValue
        let number = Double.random(in: lowerBound...upperBound)
        return Decimal(number)
    }
}

struct ProductId {
    static var currentId: Int64 = 0

    static var next: Int64 {
        currentId += 1
        return currentId
    }

    static var current: Int64 {
        currentId
    }
}
