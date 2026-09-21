import Foundation

/// POS staff role preset from the `preset` field of `GET /wc/pos/v1/staff`. Used only for display
/// labelling — never for permission checks.
public enum POSStaffPreset: String, Codable, Hashable, Sendable {
    case admin = "pos_admin"
    case manager = "pos_manager"
    case cashier = "pos_cashier"
}
