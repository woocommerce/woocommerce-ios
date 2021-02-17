import StripeTerminal

extension Charge {

    /// Convenience initializer
    /// - Parameter charge: An instance of a StripeTerminal.SCPCharge
    init(charge: SCPCharge) {
        self.identifier = charge.stripeId
        self.amount = Int(charge.amount)
        self.currency = charge.currency
        self.status = ChargeStatus.with(status: charge.status)
        self.description = charge.description
        self.metadata = charge.metadata
    }
}
