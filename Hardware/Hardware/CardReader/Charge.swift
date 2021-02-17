/// A struct representing a charge.
public struct Charge {
    /// The unique identifier for the charge.
    let identifier: String

    /// The amount of the charge.
    let amount: Int

    /// The currency of the charge
    let currency: String

    /// The status of a charge
    let status: ChargeStatus

    /// A string describing the charge.
    let description: String

    /// Metadata associated with the charge.
    let metadata: [AnyHashable: Any]?
}


extension Charge: Equatable {
    public static func ==(lhs: Charge, rhs: Charge) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
