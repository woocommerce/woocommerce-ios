import Foundation
import enum Networking.POSAuthError
import Observation

/// A POS staff member returned by the staff status endpoint.
public struct POSStaffMemberStatus: Equatable, Sendable {
    public let userID: Int64
    public let displayName: String
    public let role: String
    public let hasPIN: Bool

    public init(userID: Int64, displayName: String, role: String, hasPIN: Bool) {
        self.userID = userID
        self.displayName = displayName
        self.role = role
        self.hasPIN = hasPIN
    }
}

/// Response from POST /wc/v3/pos/auth/pin
public struct POSPINAuthResponse: Decodable, Equatable, Sendable {
    public let userID: Int64
    public let userLogin: String
    public let displayName: String
    public let role: String
    public let capabilities: [String: Bool]
    public let applicationPassword: String
    public let applicationPasswordUUID: String
    public let sessionExpires: String
    public let idleTimeoutSeconds: Int

    private enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case userLogin = "user_login"
        case displayName = "display_name"
        case role
        case capabilities
        case applicationPassword = "application_password"
        case applicationPasswordUUID = "application_password_uuid"
        case sessionExpires = "session_expires"
        case idleTimeoutSeconds = "idle_timeout_seconds"
    }

    public init(userID: Int64,
                userLogin: String,
                displayName: String,
                role: String,
                capabilities: [String: Bool],
                applicationPassword: String,
                applicationPasswordUUID: String,
                sessionExpires: String,
                idleTimeoutSeconds: Int) {
        self.userID = userID
        self.userLogin = userLogin
        self.displayName = displayName
        self.role = role
        self.capabilities = capabilities
        self.applicationPassword = applicationPassword
        self.applicationPasswordUUID = applicationPasswordUUID
        self.sessionExpires = sessionExpires
        self.idleTimeoutSeconds = idleTimeoutSeconds
    }
}

/// Credential received after successful PIN authentication, used for subsequent API calls.
public struct POSSessionCredential: Equatable, Sendable {
    public let applicationPassword: String
    public let uuid: String
    public let sessionExpires: String
    public let idleTimeoutSeconds: Int

    public init(applicationPassword: String,
                uuid: String,
                sessionExpires: String,
                idleTimeoutSeconds: Int) {
        self.applicationPassword = applicationPassword
        self.uuid = uuid
        self.sessionExpires = sessionExpires
        self.idleTimeoutSeconds = idleTimeoutSeconds
    }
}

/// Response from POST /wc/v3/pos/auth/pin/verify
/// Verifies a PIN and returns user identity and capabilities without creating a session.
public struct POSPINVerifyResponse: Equatable, Sendable {
    public let userID: Int64
    public let displayName: String
    public let role: String
    public let capabilities: [String: Bool]

    public init(userID: Int64,
                displayName: String,
                role: String,
                capabilities: [String: Bool]) {
        self.userID = userID
        self.displayName = displayName
        self.role = role
        self.capabilities = capabilities
    }
}

/// Response from POST /wc/v3/pos/auth/approve
public struct POSApprovalResponse: Decodable, Equatable, Sendable {
    public let approved: Bool
    public let approverID: Int64
    public let approverName: String
    public let approvalToken: String
    public let expiresIn: Int

    private enum CodingKeys: String, CodingKey {
        case approved
        case approverID = "approver_id"
        case approverName = "approver_name"
        case approvalToken = "approval_token"
        case expiresIn = "expires_in"
    }

    public init(approved: Bool,
                approverID: Int64,
                approverName: String,
                approvalToken: String,
                expiresIn: Int) {
        self.approved = approved
        self.approverID = approverID
        self.approverName = approverName
        self.approvalToken = approvalToken
        self.expiresIn = expiresIn
    }
}

/// Remote POS permission provider that authenticates operators via the backend REST API.
/// Capabilities come from the server response rather than hardcoded sets.
/// Networking dependencies are injected as closures to decouple from the Networking/Yosemite layer.
@Observable
public final class RemotePOSPermissionProvider: POSPermissionProviding {

    // MARK: - Auto-Lock

    public static let defaultAutoLockTimeout: TimeInterval = 300

    public var autoLockTimeoutSeconds: Int {
        sessionCredential?.idleTimeoutSeconds ?? Int(Self.defaultAutoLockTimeout)
    }

    // MARK: - POSPermissionProviding

    public private(set) var currentOperator: POSOperator?
    public private(set) var isLocked: Bool = false

    /// Whether any staff member on the backend has a PIN configured.
    ///
    /// Initialized from the last-known value persisted in `UserDefaults` so
    /// relaunches don't flash the PIN entry view before the first fetch
    /// completes. Defaults to `true` on first-ever launch (security-safe).
    /// Updated by `refreshPINStatus()`; becomes `false` when every returned
    /// staff member has `hasPIN == false`, which covers "admin deleted all
    /// users / removed all PINs" — in that case we also drop any persisted
    /// `isLocked` flag so the operator isn't trapped at a lock screen that
    /// nobody can unlock.
    public private(set) var hasAnyPINs: Bool

    // MARK: - Session State

    private(set) var sessionCredential: POSSessionCredential?

    // MARK: - Private

    private static let isLockedKey = POSLockStateKey.isLocked
    /// Persisted last-known value of `hasAnyPINs` so a relaunch doesn't flash the
    /// lock screen before the first `refreshPINStatus()` network call completes.
    private static let hasAnyPINsKey = "com.woocommerce.pos.hasAnyPINs"
    private var autoLockTimer: Timer?

    // MARK: - Callbacks

    /// Called when the POS session locks, allowing the app target to revert credential overrides.
    public var onLock: (() -> Void)?

    /// Called after successful PIN authentication, providing the operator's credentials
    /// for the app target to override the network layer.
    public var onAuthenticated: ((POSPINAuthResponse) -> Void)?

    // MARK: - Dependencies

    private let approvalService: POSApprovalServiceProtocol
    private let authenticatePINRemote: (String, String) async throws -> POSPINAuthResponse
    private let verifyPINRemote: (String) async throws -> POSPINVerifyResponse
    private let fetchStaffStatusRemote: () async throws -> [POSStaffMemberStatus]
    private let appAccountUserID: Int64

    // MARK: - Init

    /// Creates a remote permission provider.
    /// - Parameters:
    ///   - approvalService: Service for requesting manager approval.
    ///   - authenticatePINRemote: Closure that calls POST /wc/v3/pos/auth/pin. Parameters: (pin, registerID).
    ///   - verifyPINRemote: Closure that calls POST /wc/v3/pos/auth/pin/verify. Parameter: pin.
    ///   - fetchStaffStatusRemote: Closure that calls GET /wc/v3/pos/auth/pin/status. Used to discover
    ///     whether any staff have a PIN configured, so the lock screen can be skipped when none do.
    ///   - appAccountUserID: The userID of the WP-authenticated app account holder.
    public init(approvalService: POSApprovalServiceProtocol,
                authenticatePINRemote: @escaping (String, String) async throws -> POSPINAuthResponse,
                verifyPINRemote: @escaping (String) async throws -> POSPINVerifyResponse,
                fetchStaffStatusRemote: @escaping () async throws -> [POSStaffMemberStatus],
                appAccountUserID: Int64) {
        self.approvalService = approvalService
        self.authenticatePINRemote = authenticatePINRemote
        self.verifyPINRemote = verifyPINRemote
        self.fetchStaffStatusRemote = fetchStaffStatusRemote
        self.appAccountUserID = appAccountUserID
        self.isLocked = UserDefaults.standard.bool(forKey: Self.isLockedKey)
        // Restore last-known state so the lock screen doesn't flash before the
        // first network refresh. First-ever launch has no saved value -> default
        // to `true` (show lock screen until refresh confirms otherwise).
        self.hasAnyPINs = UserDefaults.standard.object(forKey: Self.hasAnyPINsKey) as? Bool ?? true
    }

    /// Fetches the current staff list and updates `hasAnyPINs` based on whether any member has a PIN.
    ///
    /// If the fetched list contains no staff with a PIN, this also clears `isLocked` (including the
    /// persisted UserDefaults flag) so a previously-locked session doesn't trap the operator at a
    /// lock screen that nobody can unlock — the case when the admin deletes all users or removes
    /// all PINs while POS is locked.
    ///
    /// On fetch failure the cached value is left untouched (`hasAnyPINs` stays `true` by default),
    /// which keeps the lock screen shown and preserves the security boundary.
    public func refreshPINStatus() async {
        do {
            let staff = try await fetchStaffStatusRemote()
            let anyPINs = staff.contains { $0.hasPIN }
            hasAnyPINs = anyPINs
            UserDefaults.standard.set(anyPINs, forKey: Self.hasAnyPINsKey)
            if !anyPINs && isLocked {
                isLocked = false
                UserDefaults.standard.set(false, forKey: Self.isLockedKey)
            }
        } catch {
            // Leave hasAnyPINs at its current value; default `true` keeps the lock screen up.
        }
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
        let useBackendApproval = POSCapability(rawValue: capability)?.supportsBackendApproval ?? false
        if useBackendApproval {
            return try await requestApproval(managerPIN: managerPIN, action: capability, orderID: orderID)
        } else {
            return try await verifyPINAndCheckCapability(pin: managerPIN, capability: capability)
        }
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
        sessionCredential = nil
        isLocked = true
        UserDefaults.standard.set(true, forKey: Self.isLockedKey)
        onLock?()
    }

    public func resetInactivityTimer() {
        guard currentOperator != nil else { return }
        startAutoLockTimer()
    }

    // MARK: - Auto-Lock Timer

    private func startAutoLockTimer() {
        autoLockTimer?.invalidate()
        let timer = Timer(timeInterval: TimeInterval(autoLockTimeoutSeconds), repeats: false) { [weak self] _ in
            self?.lock()
        }
        // Schedule in `.common` so the timer still fires during UI tracking
        // (scrolls, active animations), where `.default` mode would be starved.
        RunLoop.main.add(timer, forMode: .common)
        autoLockTimer = timer
    }

    // MARK: - Remote Authentication

    /// Authenticates a PIN against the backend REST API and signs in the resulting operator.
    /// - Parameters:
    ///   - pin: The operator's PIN.
    ///   - registerID: The POS register identifier.
    /// - Returns: The authenticated operator.
    @discardableResult
    public func authenticateRemotePIN(_ pin: String, registerID: String) async throws -> POSOperator {
        let response = try await authenticatePINRemote(pin, registerID)

        let enabledCapabilities = Set(
            response.capabilities
                .filter { $0.value }
                .map { $0.key }
        )

        let isAppAccountHolder = response.userID == appAccountUserID

        let posOperator = POSOperator(
            userID: response.userID,
            displayName: response.displayName,
            role: response.role,
            capabilities: enabledCapabilities,
            isAppAccountHolder: isAppAccountHolder
        )

        sessionCredential = POSSessionCredential(
            applicationPassword: response.applicationPassword,
            uuid: response.applicationPasswordUUID,
            sessionExpires: response.sessionExpires,
            idleTimeoutSeconds: response.idleTimeoutSeconds
        )

        onAuthenticated?(response)

        signIn(posOperator)
        return posOperator
    }

    // MARK: - Manager Approval

    /// Requests manager approval for a restricted action via the approval service.
    /// - Parameters:
    ///   - managerPIN: The manager's PIN.
    ///   - action: The capability being approved (e.g. "woocommerce_refund_orders").
    ///   - orderID: The order ID for context, if applicable.
    /// - Returns: An approval token string.
    private func requestApproval(managerPIN: String,
                                 action: String,
                                 orderID: Int64? = nil) async throws -> String {
        var context: [String: Int64] = [:]
        if let orderID {
            context["order_id"] = orderID
        }
        return try await approvalService.requestApproval(pin: managerPIN,
                                                          action: action,
                                                          context: context)
    }

    /// Verifies a PIN via the dedicated verify endpoint and checks if the user has the required capability.
    /// Used for actions that the backend approval endpoint doesn't support (e.g. settings, exit POS).
    /// Unlike /pos/auth/pin, this does not create an Application Password session.
    private func verifyPINAndCheckCapability(pin: String, capability: String) async throws -> String? {
        let response = try await verifyPINRemote(pin)
        let enabledCapabilities = Set(
            response.capabilities
                .filter { $0.value }
                .map { $0.key }
        )
        guard enabledCapabilities.contains(capability) else {
            throw POSAuthError.approvalForbidden
        }
        return nil
    }
}
