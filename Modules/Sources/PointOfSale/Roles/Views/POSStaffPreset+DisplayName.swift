import Foundation
import enum Yosemite.POSStaffPreset

extension POSStaffPreset {
    /// Short, localized label for the role (e.g. "Cashier"), shown beside the operator name in the POS
    /// floating-control menu. (The staff settings list uses its own, more explicit labels.)
    var displayName: String {
        switch self {
        case .admin:
            return Localization.admin
        case .manager:
            return Localization.manager
        case .cashier:
            return Localization.cashier
        }
    }
}

private extension POSStaffPreset {
    enum Localization {
        static let admin = NSLocalizedString(
            "pos.staffPreset.admin",
            value: "Admin",
            comment: "Display name for the admin POS staff role."
        )
        static let manager = NSLocalizedString(
            "pos.staffPreset.manager",
            value: "Manager",
            comment: "Display name for the manager POS staff role."
        )
        static let cashier = NSLocalizedString(
            "pos.staffPreset.cashier",
            value: "Cashier",
            comment: "Display name for the cashier POS staff role."
        )
    }
}
