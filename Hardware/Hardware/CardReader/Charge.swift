/// A struct representing a charge.
public struct Charge: Identifiable {
    /// The unique identifier for the charge.
    public let id: String

    /// The amount of the charge.
    public let amount: UInt

    /// The currency of the charge
    public let currency: String

    /// The status of a charge
    public let status: ChargeStatus

    /// A string describing the charge.
    public let description: String?

    /// Metadata associated with the charge.
    public let metadata: [AnyHashable: Any]?

    /// The payment method associated with the charge.
    public let paymentMethod: PaymentMethod?
}
