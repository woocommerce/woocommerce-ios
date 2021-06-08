import Foundation

/// Represents a Payment Gateway Account.
///
public struct PaymentGatewayAccount {

    /// Site identifier.
    ///
    public let siteID: Int64

    public let gatewayID: String

    public let status: String

    public let hasPendingRequirements: Bool

    public let hasOverdueRequirements: Bool

    public let currentDeadline: Date?

    public let statementDescriptor: String

    public let defaultCurrency: String

    public let supportedCurrencies: [String]

    public let country: String

    /// A boolean flag indicating if this Account is eligible for card present payments
    public let isCardPresentEligible: Bool

    /// Struct initializer
    ///
    public init(siteID: Int64,
                gatewayID: String,
                status: String,
                hasPendingRequirements: Bool,
                hasOverdueRequirements: Bool,
                currentDeadline: Date?,
                statementDescriptor: String,
                defaultCurrency: String,
                supportedCurrencies: [String],
                country: String,
                isCardPresentEligible: Bool
        ) {
        self.siteID = siteID
        self.gatewayID = gatewayID
        self.status = status
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
