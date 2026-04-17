import Foundation
import Observation
import enum Networking.POSAuthError

/// Local POS permission provider that uses on-device PINs with hardcoded capability sets.
/// Authenticates operators via PIN verification against the local Keychain.
@Observable
public final class LocalPOSPermissionProvider: POSPermissionProviding {

    // MARK: - Capability Sets

    /// All capabilities for the local admin role (the app account holder).
    public static let adminCapabilities: Set<String> = Set(
        POSCapability.allCases.map(\.rawValue)
    )

    /// Minimal capabilities for the local cashier role.
    public static let cashierCapabilities: Set<String> = []

    // MARK: - Auto-Lock

    public static let autoLockTimeout: TimeInterval = 300

    public var autoLockTimeoutSeconds: Int {
        Int(Self.autoLockTimeout)
    }

    // MARK: - POSPermissionProviding

    public private(set) var currentOperator: POSOperator?
    public private(set) var isLocked: Bool = false

    // MARK: - Private

    private static let isLockedKey = POSLockStateKey.isLocked

    private let pinService: POSPINService
    private let appAccountUserID: Int64
    private let appAccountDisplayName: String
    private var autoLockTimer: Timer?
    private let rateLimiter = POSLocalRateLimiter()

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
        try rateLimiter.checkAllowed()
        guard verifyManagerPIN(managerPIN) else {
            rateLimiter.recordFailure()
            throw try rateLimiter.errorForCurrentState(fallback: .invalidPIN)
        }
        rateLimiter.reset()
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
    /// Returns the created operator on success, nil if no match.
    /// Throws `POSAuthError.rateLimited` if too many failed attempts.
    @discardableResult
    public func authenticatePIN(_ pin: String) throws -> POSOperator? {
        try rateLimiter.checkAllowed()
        guard let role = pinService.verifyPIN(pin) else {
            rateLimiter.recordFailure()
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

        rateLimiter.reset()
        signIn(op)
        return op
    }

    /// Whether too many failed PIN attempts have permanently locked the device.
    /// The only recovery is to log out.
    public var isPermanentlyLocked: Bool {
        rateLimiter.isPermanentlyLocked
    }

    /// Verifies a manager PIN without signing in. Used for manager override approval.
    public func verifyManagerPIN(_ pin: String) -> Bool {
        pinService.verifyPIN(pin, for: .manager)
    }
}
