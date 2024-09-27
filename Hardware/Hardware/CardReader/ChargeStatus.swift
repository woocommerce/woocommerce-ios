import Codegen

/// The possible statuses for a charge
public enum ChargeStatus: Equatable, GeneratedFakeable, Codable {
    /// The charge succeeded.
    case succeeded

    /// The charge is pending.
    case pending

    /// The charge failed.
    case failed
}
