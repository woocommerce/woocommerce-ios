import Foundation
import Codegen

/// Represents a Payment Gateway Account.
///
public struct PaymentGatewayAccount: Equatable, GeneratedCopiable, GeneratedFakeable {

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

    /// Indicates if the account is live (i.e. can accept actual payments)
    public let isLive: Bool

    /// Indicates if the gateway is set for test mode. This is NOT the same as
    /// whether the account is live or not. You can have a live account set for
    /// test mode, although we cannot accept in-person payments in that situation.
    public let isInTestMode: Bool

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
                isCardPresentEligible: Bool,
                isLive: Bool,
                isInTestMode: Bool
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
        self.isLive = isLive
        self.isInTestMode = isInTestMode
    }
}
