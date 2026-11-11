import Foundation

/// The M1 local permission sets. Each role has its own local PIN.
enum POSRole: String, CaseIterable, Codable, Sendable {
    case admin
    case cashier

    var capabilities: Set<POSCapability> {
        switch self {
        case .admin:
            Set(POSCapability.allCases)
        case .cashier:
            [.processSales, .viewOrders, .applyCoupons]
        }
    }

    var displayName: String {
        switch self {
        case .admin:
            Localization.admin
        case .cashier:
            Localization.cashier
        }
    }
}

private extension POSRole {
    enum Localization {
        static let admin = NSLocalizedString(
            "pos.staffPreset.admin",
            value: "Admin",
            comment: "Display name for the admin POS staff role."
        )
        static let cashier = NSLocalizedString(
            "pos.staffPreset.cashier",
            value: "Cashier",
            comment: "Display name for the cashier POS staff role."
        )
    }
}
