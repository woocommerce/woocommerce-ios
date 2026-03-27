import Foundation

struct LocalOperatorCapabilities: Equatable {
    let canViewAnalytics: Bool
    let canAccessAdminSettings: Bool
    let canManageLocalOperators: Bool
    let canCreateOrders: Bool

    static let unrestricted = LocalOperatorCapabilities(
        canViewAnalytics: true,
        canAccessAdminSettings: true,
        canManageLocalOperators: true,
        canCreateOrders: true
    )

    static let cashier = LocalOperatorCapabilities(
        canViewAnalytics: false,
        canAccessAdminSettings: false,
        canManageLocalOperators: false,
        canCreateOrders: true
    )
}

enum LocalOperatorRole: String, Codable, CaseIterable, Identifiable {
    case manager
    case cashier

    var id: String { rawValue }

    var capabilities: LocalOperatorCapabilities {
        switch self {
        case .manager:
            .unrestricted
        case .cashier:
            .cashier
        }
    }

    var displayName: String {
        switch self {
        case .manager:
            NSLocalizedString("Manager", comment: "Display name for the local operator manager role.")
        case .cashier:
            NSLocalizedString("Cashier", comment: "Display name for the local operator cashier role.")
        }
    }
}

struct LocalOperatorProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var displayName: String
    var role: LocalOperatorRole
    var isEnabled: Bool
    var pinReference: String

    init(id: UUID = UUID(),
         displayName: String,
         role: LocalOperatorRole,
         isEnabled: Bool = true,
         pinReference: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.role = role
        self.isEnabled = isEnabled
        self.pinReference = pinReference ?? id.uuidString
    }
}

struct LocalOperatorSettings: Codable, Equatable {
    var isDeviceStaffModeEnabled: Bool
    var inactivityTimeout: TimeInterval

    static let `default` = LocalOperatorSettings(
        isDeviceStaffModeEnabled: false,
        inactivityTimeout: 5 * 60
    )
}

protocol LocalOperatorCapabilitiesProviding: AnyObject {
    var isDeviceStaffModeEnabled: Bool { get }
    var activeOperator: LocalOperatorProfile? { get }
    var currentCapabilities: LocalOperatorCapabilities { get }
    func canViewAnalytics() -> Bool
    func canAccessAdminSettings() -> Bool
    func canManageLocalOperators() -> Bool
}

protocol LocalOperatorStoreProtocol: AnyObject {
    var settings: LocalOperatorSettings { get set }
    func loadProfiles() -> [LocalOperatorProfile]
    func saveProfiles(_ profiles: [LocalOperatorProfile])
}

protocol PINVerificationServiceProtocol {
    func storePIN(_ pin: String, for reference: String) throws
    func verifyPIN(_ pin: String, for reference: String) -> Bool
    func deletePIN(for reference: String)
}
