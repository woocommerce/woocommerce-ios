import Foundation
import Observation

/// Local POS permission provider that uses on-device PINs with hardcoded capability sets.
/// Authenticates operators via PIN verification against the local Keychain.
@Observable
final class LocalPOSPermissionProvider: POSPermissionProviding {

    // MARK: - Capability Sets

    static let managerCapabilities: Set<String> = [
        "woocommerce_pos_access",
        "woocommerce_pos_manage_settings",
        "woocommerce_void_orders",
        "woocommerce_refund_orders",
        "woocommerce_apply_discounts",
        "woocommerce_override_prices",
        "woocommerce_view_sales_reports",
        "woocommerce_view_personal_sales",
        "woocommerce_approve_overrides",
        "woocommerce_view_customer_data",
        "woocommerce_edit_customer_data",
        "woocommerce_adjust_stock",
        "woocommerce_view_audit_logs",
    ]

    static let cashierCapabilities: Set<String> = [
        "woocommerce_pos_access",
        "woocommerce_view_personal_sales",
        "woocommerce_view_customer_data",
    ]

    // MARK: - POSPermissionProviding

    private(set) var currentOperator: POSOperator?
    private(set) var isLocked: Bool = false

    // MARK: - Private

    private let pinService: POSPINService
    private let appAccountUserID: Int64
    private let appAccountDisplayName: String

    // MARK: - Init

    init(pinService: POSPINService,
         appAccountUserID: Int64,
         appAccountDisplayName: String) {
        self.pinService = pinService
        self.appAccountUserID = appAccountUserID
        self.appAccountDisplayName = appAccountDisplayName
    }

    // MARK: - POSPermissionProviding

    func checkPermission(_ capability: String) -> POSPermissionResult {
        guard let op = currentOperator else {
            return .requiresOverride
        }
        if op.hasCapability(capability) {
            return .allowed
        }
        return .requiresOverride
    }

    func hasCapability(_ capability: String) -> Bool {
        currentOperator?.hasCapability(capability) ?? false
    }

    func signIn(_ posOperator: POSOperator) {
        currentOperator = posOperator
        isLocked = false
    }

    func lock() {
        currentOperator = nil
        isLocked = true
    }

    // MARK: - PIN Authentication

    /// Whether any PINs are configured in the PIN service.
    var hasAnyPINs: Bool {
        PINRole.allCases.contains { pinService.hasPIN(for: $0) }
    }

    /// Verifies a PIN against all roles and signs in the matching operator.
    /// Returns the created operator on success, or nil if no match.
    func authenticatePIN(_ pin: String) -> POSOperator? {
        guard let role = pinService.verifyPIN(pin) else {
            return nil
        }

        let op: POSOperator
        switch role {
        case .manager:
            op = POSOperator(
                userID: appAccountUserID,
                displayName: appAccountDisplayName,
                role: "pos_manager",
                capabilities: Self.managerCapabilities,
                isAppAccountHolder: true
            )
        case .cashier:
            op = POSOperator(
                userID: 0,
                displayName: "Cashier",
                role: "pos_cashier",
                capabilities: Self.cashierCapabilities,
                isAppAccountHolder: false
            )
        }

        signIn(op)
        return op
    }

    /// Verifies a manager PIN without signing in. Used for manager override approval.
    func verifyManagerPIN(_ pin: String) -> Bool {
        pinService.verifyPIN(pin, for: .manager)
    }

    /// Verifies the app account holder PIN. Used for exiting POS.
    func verifyAccountHolderPIN(_ pin: String) -> Bool {
        pinService.verifyPIN(pin, for: .manager)
    }
}
