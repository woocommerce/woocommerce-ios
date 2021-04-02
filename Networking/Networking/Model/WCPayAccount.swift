/// Represent a WCPay accont Entity.
///
public struct WCPayAccount: Decodable {
    public static let nullDeadline = Date(timeIntervalSince1970: 0)

    public let status: WCPayAccountStatusEnum
    public let hasPendingRequirements: Bool
    public let hasOverdueRequirements: Bool
    public let currentDeadline: Date?
    public let statementDescriptor: String
    public let defaultCurrency: String
    public let supportedCurrencies: [String]
    public let country: String

    public init(
        status: WCPayAccountStatusEnum,
        hasPendingRequirements: Bool,
        hasOverdueRequirements: Bool,
        currentDeadline: Date?,
        statementDescriptor: String,
        defaultCurrency: String,
        supportedCurrencies: [String],
        country: String
    ) {
        self.status = status
        self.hasPendingRequirements = hasPendingRequirements
        self.hasOverdueRequirements = hasOverdueRequirements
        self.currentDeadline = currentDeadline
        self.statementDescriptor = statementDescriptor
        self.defaultCurrency = defaultCurrency
        self.supportedCurrencies = supportedCurrencies
        self.country = country
    }

    /// The public initializer for WCPay Account.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let status = try container.decode(WCPayAccountStatusEnum.self, forKey: .status)
        let hasPendingRequirements = try container.decode(Bool.self, forKey: .hasPendingRequirements)
        let hasOverdueRequirements = try container.decode(Bool.self, forKey: .hasOverdueRequirements)
        let currentDeadline = try container.decodeIfPresent(Date.self, forKey: .currentDeadline)
        let statementDescriptor = try container.decode(String.self, forKey: .statementDescriptor)
        let currencyContainer = try container.nestedContainer(keyedBy: CurrencyCodingKeys.self, forKey: .storeCurrencies)
        let defaultCurrency = try currencyContainer.decode(String.self, forKey: .defaultCurrency)
        let supportedCurrencies = try currencyContainer.decode([String].self, forKey: .supported)
        let country = try container.decode(String.self, forKey: .country)

        self.init(
            status: status,
            hasPendingRequirements: hasPendingRequirements,
            hasOverdueRequirements: hasOverdueRequirements,
            currentDeadline: currentDeadline,
            statementDescriptor: statementDescriptor,
            defaultCurrency: defaultCurrency,
            supportedCurrencies: supportedCurrencies,
            country: country
        )
    }

    /// Convenience initializer for the exceptional case where the self-hosted
    /// site has WCPay active, but the merchant has not on-boarded
    ///
    public init(status: WCPayAccountStatusEnum) {
        self.init(
            status: status,
            hasPendingRequirements: false,
            hasOverdueRequirements: false,
            currentDeadline: nil,
            statementDescriptor: "",
            defaultCurrency: "",
            supportedCurrencies: [],
            country: ""
        )
    }
}

private extension WCPayAccount {
    enum CodingKeys: String, CodingKey {
        case status = "status"
        case hasPendingRequirements = "has_pending_requirements"
        case hasOverdueRequirements = "has_overdue_requirements"
        case currentDeadline = "current_deadline"
        case statementDescriptor = "statement_descriptor"
        case storeCurrencies = "store_currencies"
        case country = "country"
    }

    enum CurrencyCodingKeys: String, CodingKey {
        case defaultCurrency = "default"
        case supported = "supported"
    }
}
