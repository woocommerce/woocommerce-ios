import Hardware

extension WCPayAccount {
    /// Maps a WCPayAccount into the PaymentGatewayAccount struct
    ///
    func toPaymentGatewayAccount(siteID: Int64) -> PaymentGatewayAccount { // TODO can we add siteID to WCPayAccount?
        return PaymentGatewayAccount(
            siteID: siteID,
            gatewayID: WCPayAccount.gatewayID,
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
