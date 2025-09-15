import Foundation

/// Represent a PayPal account Entity for card present payments.
///
public struct PayPalAccount: Decodable {
    public static let gatewayID = "paypal"

    public let status: WCPayAccountStatusEnum
    /// Indicates whether the payment gateway is a live account that can accept actual payments, or just a test/developer account.
    /// Not to be confused with "test mode" which is a separate concept (see `isInTestMode`)
    ///
    public let isLiveAccount: Bool
    /// Indicates whether the payment gateway is currently in "Test" or "Debug" mode
    ///
    public let isInTestMode: Bool
    public let hasPendingRequirements: Bool
    public let hasOverdueRequirements: Bool
    public let currentDeadline: Date?
    /// An alphanumeric string set by the merchant, e.g. `MYSTORE.COM`
    public let statementDescriptor: String
    /// A three character lowercase currency code, e.g. `usd`
    public let defaultCurrency: String
    public let supportedCurrencies: [String]
    /// A two character country code, e.g. `US`
    public let country: String
    /// A boolean flag indicating if this Account is eligible for card present payments
    public let isCardPresentEligible: Bool

    public init(
        status: WCPayAccountStatusEnum,
        isLiveAccount: Bool,
        isInTestMode: Bool,
        hasPendingRequirements: Bool,
        hasOverdueRequirements: Bool,
        currentDeadline: Date?,
        statementDescriptor: String,
        defaultCurrency: String,
        supportedCurrencies: [String],
        country: String,
        isCardPresentEligible: Bool
    ) {
        self.status = status
        self.isLiveAccount = isLiveAccount
        self.isInTestMode = isInTestMode
        self.hasPendingRequirements = hasPendingRequirements
        self.hasOverdueRequirements = hasOverdueRequirements
        self.currentDeadline = currentDeadline
        self.statementDescriptor = statementDescriptor
        self.defaultCurrency = defaultCurrency
        self.supportedCurrencies = supportedCurrencies
        self.country = country
        self.isCardPresentEligible = isCardPresentEligible
    }
}

extension PayPalAccount {
    /// Creates a mock PayPal account for POC testing
    public static func mockAccount() -> PayPalAccount {
        return PayPalAccount(
            status: .complete,
            isLiveAccount: false,
            isInTestMode: true,
            hasPendingRequirements: false,
            hasOverdueRequirements: false,
            currentDeadline: nil,
            statementDescriptor: "PAYPAL STORE",
            defaultCurrency: "usd",
            supportedCurrencies: ["usd", "eur", "gbp"],
            country: "US",
            isCardPresentEligible: true
        )
    }
}

/// PayPal Account: Coding Keys
///
private extension PayPalAccount {
    enum CodingKeys: String, CodingKey {
        case status
        case isLiveAccount = "is_live"
        case isInTestMode = "is_in_test_mode"
        case hasPendingRequirements = "has_pending_requirements"
        case hasOverdueRequirements = "has_overdue_requirements"
        case currentDeadline = "current_deadline"
        case statementDescriptor = "statement_descriptor"
        case defaultCurrency = "default_currency"
        case supportedCurrencies = "supported_currencies"
        case country
        case isCardPresentEligible = "is_card_present_eligible"
    }
}