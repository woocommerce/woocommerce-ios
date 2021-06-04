import Foundation
import Storage

// MARK: - PaymentGatewayAccount: ReadOnlyConvertible
//
extension Storage.PaymentGatewayAccount: ReadOnlyConvertible {

    /// Updates the `Storage.PaymentGatewayAccount` from the ReadOnly type.
    ///
    public func update(with paymentGatewayAccount: Yosemite.WCPayAccount) {
        status = paymentGatewayAccount.status.rawValue
        hasPendingRequirements = paymentGatewayAccount.hasPendingRequirements
        hasOverdueRequirements = paymentGatewayAccount.hasOverdueRequirements
        currentDeadline = paymentGatewayAccount.currentDeadline
        statementDescriptor = paymentGatewayAccount.statementDescriptor
        defaultCurrency = paymentGatewayAccount.defaultCurrency
        supportedCurrencies = paymentGatewayAccount.supportedCurrencies
        country = paymentGatewayAccount.country
        isCardPresentEligible = paymentGatewayAccount.isCardPresentEligible
    }

    /// Returns a ReadOnly version for Yosemite.
    ///
    public func toReadOnly() -> Yosemite.WCPayAccount {
        let accountStatus = Yosemite.WCPayAccountStatusEnum.init(rawValue: status)

        return WCPayAccount(status: accountStatus,
                     hasPendingRequirements: hasPendingRequirements,
                     hasOverdueRequirements: hasOverdueRequirements,
                     currentDeadline: currentDeadline,
                     statementDescriptor: statementDescriptor,
                     defaultCurrency: defaultCurrency,
                     supportedCurrencies: supportedCurrencies,
                     country: country,
                     isCardPresentEligible: isCardPresentEligible)
    }
}
