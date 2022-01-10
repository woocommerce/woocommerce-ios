import Hardware

public extension StripeAccount {
    /// Maps a StripeAccount into the PaymentGatewayAccount struct
    ///
    func toPaymentGatewayAccount(siteID: Int64) -> PaymentGatewayAccount {
        return PaymentGatewayAccount(
            siteID: siteID,
            gatewayID: StripeAccount.gatewayID,
            status: status.rawValue,
            hasPendingRequirements: hasPendingRequirements,
            hasOverdueRequirements: hasOverdueRequirements,
            currentDeadline: currentDeadline,
            statementDescriptor: statementDescriptor,
            defaultCurrency: defaultCurrency,
            supportedCurrencies: supportedCurrencies,
            country: country,
            isCardPresentEligible: isCardPresentEligible,
            isLive: isLiveAccount,
            isInTestMode: isInTestMode
        )
    }
}
