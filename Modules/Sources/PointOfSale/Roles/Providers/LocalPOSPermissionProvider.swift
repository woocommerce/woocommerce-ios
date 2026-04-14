import Foundation
import Observation
import enum Networking.POSAuthError

/// Local POS permission provider that uses on-device PINs with hardcoded capability sets.
/// Authenticates operators via PIN verification against the local Keychain.
@Observable
public final class LocalPOSPermissionProvider: POSPermissionProviding {

    // MARK: - Capability Sets

    /// Capabilities for the local "Admin" role (the app account holder).
    /// Includes `posWriteSettings` which gates admin-only actions
    /// like managing staff and exiting POS.
    public static let adminCapabilities: Set<String> = [
        "woocommerce_pos_access",
        "woocommerce_pos_read_settings",
        "woocommerce_pos_write_settings",
        "woocommerce_void_orders",
        "woocommerce_refund_orders",
        "woocommerce_apply_discounts",
        "woocommerce_override_prices",
        "woocommerce_view_sales_reports",
        "woocommerce_view_personal_sales",
        "woocommerce_view_customer_data",
        "woocommerce_edit_customer_data",
        "woocommerce_adjust_stock",
        "woocommerce_view_audit_logs",
    ]

    public static let cashierCapabilities: Set<String> = [
        "woocommerce_pos_access",
        "woocommerce_view_personal_sales",
        "woocommerce_view_customer_data",
    ]

    // MARK: - Auto-Lock

    public static let autoLockTimeout: TimeInterval = 300

    public var autoLockTimeoutSeconds: Int {
        Int(Self.autoLockTimeout)
    }

    // MARK: - POSPermissionProviding

    public private(set) var currentOperator: POSOperator?
    public private(set) var isLocked: Bool = false

    // MARK: - Private

    private static let isLockedKey = "com.woocommerce.pos.isLocked"

    private let pinService: POSPINService
    private let appAccountUserID: Int64
    private let appAccountDisplayName: String
    private var autoLockTimer: Timer?

    // MARK: - Init

    public init(pinService: POSPINService,
                appAccountUserID: Int64,
                appAccountDisplayName: String) {
        self.pinService = pinService
        self.appAccountUserID = appAccountUserID
        self.appAccountDisplayName = appAccountDisplayName
        self.isLocked = UserDefaults.standard.bool(forKey: Self.isLockedKey)
    }

    // MARK: - POSPermissionProviding

    public func checkPermission(_ capability: String) -> POSPermissionResult {
        guard let op = currentOperator else {
            return .requiresOverride
        }
        resetInactivityTimer()
        if op.hasCapability(capability) {
            return .allowed
        }
        return .requiresOverride
    }

    public func hasCapability(_ capability: String) -> Bool {
        currentOperator?.hasCapability(capability) ?? false
    }

    public func requestManagerApproval(managerPIN: String, for capability: String, orderID: Int64?) async throws -> String? {
        guard verifyManagerPIN(managerPIN) else {
            throw POSAuthError.invalidPIN
        }
        return nil
    }

    public func signIn(_ posOperator: POSOperator) {
        currentOperator = posOperator
        isLocked = false
        UserDefaults.standard.set(false, forKey: Self.isLockedKey)
        startAutoLockTimer()
    }

    public func lock() {
        autoLockTimer?.invalidate()
        autoLockTimer = nil
        currentOperator = nil
        isLocked = true
        UserDefaults.standard.set(true, forKey: Self.isLockedKey)
    }

    public func resetInactivityTimer() {
        guard currentOperator != nil else { return }
        startAutoLockTimer()
    }

    // MARK: - Auto-Lock Timer

    private func startAutoLockTimer() {
        autoLockTimer?.invalidate()
        autoLockTimer = Timer.scheduledTimer(withTimeInterval: Self.autoLockTimeout, repeats: false) { [weak self] _ in
            self?.lock()
        }
    }

    // MARK: - PIN Authentication

    /// Whether any PINs are configured in the PIN service.
    public var hasAnyPINs: Bool {
        PINRole.allCases.contains { pinService.hasPIN(for: $0) }
    }

    /// Verifies a PIN against all roles and signs in the matching operator.
    /// Returns the created operator on success, or nil if no match.
    public func authenticatePIN(_ pin: String) -> POSOperator? {
        guard let role = pinService.verifyPIN(pin) else {
            return nil
        }

        let op: POSOperator
        switch role {
        case .manager:
            op = POSOperator(
                userID: appAccountUserID,
                displayName: appAccountDisplayName,
                role: "administrator",
                capabilities: Self.adminCapabilities,
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
    public func verifyManagerPIN(_ pin: String) -> Bool {
        pinService.verifyPIN(pin, for: .manager)
    }

    /// Verifies the app account holder PIN. Used for exiting POS.
    public func verifyAccountHolderPIN(_ pin: String) -> Bool {
        pinService.verifyPIN(pin, for: .manager)
    }
}
