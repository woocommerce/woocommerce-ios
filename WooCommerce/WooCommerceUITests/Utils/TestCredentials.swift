// These are fake credentials used for the mocked UI tests
struct TestCredentials {
    static let emailAddress: String = "t@wp.com"
    static let password: String = "pw"
    static let twoFACode: String = "123456"
    // Site-address login performs a live GET before calling the mocked APIs, so it must target WireMock.
    static let siteAddressLoginUrl: String = "http://localhost:8282"
    static let siteUrl: String = "https://yourwoosite.com"
    static let siteUrlHost: String = "yourwoosite.com"
    static let storeName: String = "Your WooCommerce Store"
}
