/// Represent a WCPay accont Entity.
///
public struct WCPayAccount: Decodable {
    public let defaultCurrency: String
    public let statementDescriptor: String
    public let status: WCPayAccountStatusEnum
    public let supportedCurrencies: [String]

    public init(
        defaultCurrency: String,
        statementDescriptor: String,
        status: WCPayAccountStatusEnum,
        supportedCurrencies: [String]
    ) {
        self.defaultCurrency = defaultCurrency
        self.statementDescriptor = statementDescriptor
        self.status = status
        self.supportedCurrencies = supportedCurrencies
    }

    /// The public initializer for WCPay Account.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let statementDescriptor = try container.decode(String.self, forKey: .statementDescriptor)
        let status = try container.decode(WCPayAccountStatusEnum.self, forKey: .status)

        let currencyContainer = try container.nestedContainer(keyedBy: CurrencyCodingKeys.self, forKey: .storeCurrencies)
        let defaultCurrency = try currencyContainer.decode(String.self, forKey: .defaultCurrency)
        let supportedCurrencies = try currencyContainer.decode([String].self, forKey: .supported)

        self.init(
            defaultCurrency: defaultCurrency,
            statementDescriptor: statementDescriptor,
            status: status,
            supportedCurrencies: supportedCurrencies
        )
    }
}

private extension WCPayAccount {
    enum CodingKeys: String, CodingKey {
        case statementDescriptor = "statement_descriptor"
        case status = "status"
        case storeCurrencies = "store_currencies"
    }

    enum CurrencyCodingKeys: String, CodingKey {
        case defaultCurrency = "default"
        case supported = "supported"
    }
}
