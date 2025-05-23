/// Represent a Stripe Account Entity.
///
public struct StripeAccount: Decodable {
    public static let gatewayID = "woocommerce-stripe"

    public let status: WCPayAccountStatusEnum
    /// Indicates whether the payment gateway is a live account that can accept actual payments, or just a test/developer account.
    /// Not to be confused with "test mode" which is a separate concept (see `isInTestMode`)
    /// Note: Using WCPayAccountStatusEnum is somewhat inappropriate here, since it ties this Stripe account concept
    /// to WooCommerce Payments - although in reality both extensions use the same account on the backend.
    /// TODO: Introduce a layer of abstraction and translate each extension's account status into a
    /// PaymentGatewayAccountStatusEnum or somesuch.
    ///
    public let isLiveAccount: Bool
    /// Indicates whether the payment gateway is currently in "Test" or "Debug" mode
    ///
    public let isInTestMode: Bool
    public let hasPendingRequirements: Bool
    public let hasOverdueRequirements: Bool
    public let currentDeadline: Date?
    /// An alphanumeric string set by the merchant, e.g. `MYSTORE.COM`
    /// See https://stripe.com/docs/statement-descriptors
    public let statementDescriptor: String
    /// A three character lowercase currency code, e.g. `usd`
    /// See https://stripe.com/docs/api/accounts/object#account_object-default_currency
    public let defaultCurrency: String
    public let supportedCurrencies: [String]
    /// A two character country code, e.g. `US`
    /// See https://stripe.com/docs/api/accounts/object#account_object-country
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

    /// The public initializer for WCPay Account.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let status = try container.decode(WCPayAccountStatusEnum.self, forKey: .status)
        let isLiveAccount = try container.decode(Bool.self, forKey: .isLive)
        let isInTestMode = try container.decode(Bool.self, forKey: .testMode)
        let hasPendingRequirements = try container.decode(Bool.self, forKey: .hasPendingRequirements)
        let hasOverdueRequirements = try container.decode(Bool.self, forKey: .hasOverdueRequirements)
        let currentDeadline = try container.decodeIfPresent(Date.self, forKey: .currentDeadline)
        let statementDescriptor = try container.decodeIfPresent(String.self, forKey: .statementDescriptor)
        let currencyContainer = try container.nestedContainer(keyedBy: CurrencyCodingKeys.self, forKey: .storeCurrencies)
        let defaultCurrency = try currencyContainer.decode(String.self, forKey: .defaultCurrency)
        let supportedCurrencies = try currencyContainer.decode([String].self, forKey: .supported)
        let country = try container.decode(String.self, forKey: .country)
        /// Ignore the state of the In-Person Payments Beta flag (`.cardPresentEligible`). Allow any site. See #5030
        /// let cardPresentEligible = try container.decodeIfPresent(Bool.self, forKey: .cardPresentEligible) ?? false

        self.init(
            status: status,
            isLiveAccount: isLiveAccount,
            isInTestMode: isInTestMode,
            hasPendingRequirements: hasPendingRequirements,
            hasOverdueRequirements: hasOverdueRequirements,
            currentDeadline: currentDeadline,
            statementDescriptor: statementDescriptor ?? "",
            defaultCurrency: defaultCurrency,
            supportedCurrencies: supportedCurrencies,
            country: country,
            isCardPresentEligible: true
        )
    }
}

private extension StripeAccount {
    enum CodingKeys: String, CodingKey {
        case status
        case isLive = "is_live"
        case testMode = "test_mode"
        case hasPendingRequirements = "has_pending_requirements"
        case hasOverdueRequirements = "has_overdue_requirements"
        case currentDeadline = "current_deadline"
        case statementDescriptor = "statement_descriptor"
        case storeCurrencies = "store_currencies"
        case country
        case cardPresentEligible = "card_present_eligible"
    }

    enum CurrencyCodingKeys: String, CodingKey {
        case defaultCurrency = "default"
        case supported
    }
}
