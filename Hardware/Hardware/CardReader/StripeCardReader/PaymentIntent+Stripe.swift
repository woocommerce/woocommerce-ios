import StripeTerminal

extension PaymentIntent {

    /// Convenience initializer
    /// - Parameter intent: An instance of a StripeTerminal.PaymentIntent
    init(intent: StripeTerminal.PaymentIntent) {
        self.id = intent.stripeId
        self.status = PaymentIntentStatus.with(status: intent.status)
        self.created = intent.created
        self.amount = Int(intent.amount)
        self.currency = intent.currency
        self.metadata = intent.metadata
        self.charges = intent.charges.map { .init(charge: $0) }
    }
}
