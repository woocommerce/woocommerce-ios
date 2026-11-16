import Foundation

/// The local PIN slots and their permission sets. Each role has its own PIN on this device.
enum POSLocalRole: String, CaseIterable, Codable, Sendable {
    case admin
    case cashier

    var staff: POSStaff {
        POSStaff(displayName: displayName, capabilities: capabilities)
    }

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

private extension POSLocalRole {
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
