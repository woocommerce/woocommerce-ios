import Foundation

public struct ScreenshotObjects: MockObjectGraph {

    public init() {
        // Do nothing
    }

    public let userCredentials = Credentials(
        username: i18n.DefaultAccount.username,
        authToken: UUID().uuidString,
        siteAddress: i18n.DefaultSite.url
    )

    public let defaultAccount = Account(
        userID: 1,
        displayName: i18n.DefaultAccount.displayName,
        email: i18n.DefaultAccount.email,
        username: i18n.DefaultAccount.username,
        gravatarUrl: nil
    )

    public let defaultSite = Site(
        siteID: 1,
        name: i18n.DefaultSite.name,
        description: "",
        url: i18n.DefaultSite.url,
        plan: "",
        isWooCommerceActive: true,
        isWordPressStore: true,
        timezone: "UTC",
        gmtOffset: 0
    )

    public var sites: [Site] {
        return [defaultSite]
    }

    public func accountWithId(id: Int64) -> Account {
        return defaultAccount
    }

    public func accountSettingsWithUserId(userId: Int64) -> AccountSettings {
        return .init(userID: userId, tracksOptOut: true)
    }

    public func siteWithId(id: Int64) -> Site {
        return defaultSite
    }

    public var orders: [Order] = [
        Order(
            siteID: 1,
            orderID: 1,
            parentID: 0,
            customerID: 1,
            number: "10000",
            status: .pending,
            currency: "CAD",
            customerNote: nil,
            dateCreated: Date(),
            dateModified: Date(),
            datePaid: nil,
            discountTotal: "0",
            discountTax: "0",
            shippingTotal: "0",
            shippingTax: "0",
            total: "99.99",
            totalTax: "5.23",
            paymentMethodID: "fased",
            paymentMethodTitle: "MasterCard",
            items: [],
            billingAddress: i18n.Customer1.billingAddress,
            shippingAddress: i18n.Customer1.billingAddress,
            shippingLines: [],
            coupons: [],
            refunds: []
        )
    ]

    public var products: [Product] = [
        Products.roseGoldShades,
    ]
}

struct i18n {
    struct DefaultAccount {
        static let displayName = NSLocalizedString("My Account", comment: "displayName for the screenshot demo account")
        static let email = NSLocalizedString("woocommercestore@example.com", comment: "email address for the screenshot demo account")
        static let username = NSLocalizedString("test account", comment: "username for the screenshot demo account")
    }

    struct DefaultSite {
        static let name = NSLocalizedString("Your WooCommerce Store", comment: "Store Name for the screenshot demo account")
        static let url = NSLocalizedString("example.com", comment: "")
    }

    struct Customer1: MockCustomerConvertable {
        static var firstName: String = NSLocalizedString("Phil", comment: "")
        static var lastName: String = NSLocalizedString("Smith", comment: "")
        static var company: String? = nil
        static var address1: String = NSLocalizedString("123 Pleasant Place", comment: "")
        static var address2: String? = nil
        static var city: String = NSLocalizedString("New Hamfordshireton", comment: "")
        static var state: String = NSLocalizedString("Montana", comment: "")
        static var postCode: String = NSLocalizedString("60468", comment: "")
        static var country: String = NSLocalizedString("USA", comment: "")
        static var phone: String? = NSLocalizedString("+1 135 568 9846", comment: "")
        static var email: String? = NSLocalizedString("phil.smith@example.com", comment: "")
    }
}

protocol MockCustomerConvertable {
    static var firstName: String { get }
    static var lastName: String { get }
    static var company: String? { get }
    static var address1: String { get }
    static var address2: String? { get }
    static var city: String { get }
    static var state: String { get }
    static var postCode: String { get }
    static var country: String { get }
    static var phone: String? { get }
    static var email: String? { get }

    static var billingAddress: Address { get }
}

extension MockCustomerConvertable {
    static var billingAddress: Address {
        .init(
            firstName: firstName,
            lastName: lastName,
            company: company,
            address1: address1,
            address2: address2,
            city: city,
            state: state,
            postcode: postCode,
            country: country,
            phone: phone,
            email: email
        )
    }

    static var shippingAddress: Address {
        return billingAddress
    }
}

extension ScreenshotObjects {
    struct Products {
        static let roseGoldShades = Product(
            siteID: 1,
            productID: ProductId.next,
            name: "Rose Gold shades",
            slug: "rose-gold-shades",
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
            price: "9.99",
            regularPrice: nil,
            salePrice: nil,
            onSale: false,
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
            stockQuantity: 468,
            stockStatusKey: "",
            backordersKey: "",
            backordersAllowed: false,
            backordered: false,
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
            images: [],
            attributes: [],
            defaultAttributes: [],
            variations: [],
            groupedProducts: [],
            menuOrder: 0
        )
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
