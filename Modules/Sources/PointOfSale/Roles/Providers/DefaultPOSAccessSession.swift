import Foundation
import Observation

@Observable
@MainActor
final class DefaultPOSAccessSession: POSAccessSession {
    private(set) var currentStaff: POSStaff?
    private(set) var isLocked: Bool
    private(set) var isPINProtectionEnabled: Bool

    @ObservationIgnored private let credentialProvider: POSPINCredentialProviding
    @ObservationIgnored private let siteID: Int64
    @ObservationIgnored private let authenticator: POSPINAuthenticating
    @ObservationIgnored private let recovery: POSPINRecoveryAuthenticating
    @ObservationIgnored private let rateLimiter: POSLocalRateLimiter
    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private var generation: POSPINAttemptContext.Token
    @ObservationIgnored private var isActive = true
    @ObservationIgnored private var hasKnownProtection: Bool

    init(siteID: Int64,
         authenticator: POSPINAuthenticating,
         rateLimiter: POSLocalRateLimiter,
         credentialProvider: POSPINCredentialProviding,
         recovery: POSPINRecoveryAuthenticating = UnavailablePOSPINRecovery(),
         userDefaults: UserDefaults = .standard) {
        self.credentialProvider = credentialProvider
        self.siteID = siteID
        self.authenticator = authenticator
        self.recovery = recovery
        self.rateLimiter = rateLimiter
        self.generation = rateLimiter.context.invalidate()
        self.userDefaults = userDefaults
        let hasCredentials = try? !credentialProvider.credentials().isEmpty
        self.hasKnownProtection = hasCredentials == true
        let isProtected = hasCredentials ?? true
        self.isPINProtectionEnabled = isProtected
        self.isLocked = isProtected
        // A read failure must not erase a known locked store's relaunch marker.
        // Without an existing marker, an unreadable store does not create a new cold-launch route.
        if let hasCredentials { persistLockState(hasCredentials) }
    }

    func refreshPINProtection() throws(POSPINStoreError) {
        guard isActive, let request = rateLimiter.context.invalidate(ifCurrent: generation) else {
            currentStaff = nil
            isPINProtectionEnabled = true
            isLocked = true
            throw .storageFailure
        }
        generation = request
        do {
            let isProtected = try !credentialProvider.credentials().isEmpty
            hasKnownProtection = isProtected
            let isEnablingPINProtection = isProtected && !isPINProtectionEnabled
            if isEnablingPINProtection && !isLocked {
                currentStaff = POSLocalRole.admin.staff
            } else if !isProtected {
                currentStaff = nil
                isLocked = false
            }
            isPINProtectionEnabled = isProtected
            persistLockState(isLocked)
        } catch {
            isPINProtectionEnabled = true
            currentStaff = nil
            isLocked = true
            if hasKnownProtection { persistLockState(true) }
            throw error
        }
    }

    func allows(_ capability: POSCapability) -> Bool {
        guard isActive, rateLimiter.context.isCurrent(generation) else { return false }
        // Without an Admin PIN there is nobody to sign in or approve, so every action is allowed.
        guard isPINProtectionEnabled else {
            return true
        }
        return currentStaff?.hasCapability(capability) == true
    }

    func beginPINChange() throws(POSPINStoreError) -> POSPINChangeRegistration {
        guard !isLocked, allows(.manageStoreSettings) else { throw .storageFailure }
        return rateLimiter.context.beginPINChange()
    }

    func signIn(withPIN pin: String) async throws(POSAuthError) {
        guard isActive else { throw .unknown }
        let request = generation
        let staff = try await rateLimiter.authenticate(pin: pin, using: authenticator, token: request)
        guard isActive, rateLimiter.context.isCurrent(request), !Task.isCancelled else { throw .unknown }
        currentStaff = staff
        isLocked = false
        persistLockState(false)
    }

    func requestManagerApproval(withPIN pin: String, for capability: POSCapability) async throws(POSAuthError) {
        guard isActive else { throw .unknown }
        let request = generation
        _ = try await rateLimiter.authenticate(pin: pin, using: authenticator, capability: capability, token: request)
        guard isActive, rateLimiter.context.isCurrent(request), !Task.isCancelled else { throw .unknown }
    }

    func recover() async throws(POSAuthError) {
        guard isActive else { throw .unknown }
        let request = generation
        let staff = try await rateLimiter.recover(using: recovery, token: request)
        guard isActive, rateLimiter.context.isCurrent(request), !Task.isCancelled else { throw .unknown }
        currentStaff = staff
        isLocked = false
        persistLockState(false)
    }

    func lock() {
        guard isPINProtectionEnabled else { return }
        currentStaff = nil
        isLocked = true
        guard isActive, let request = rateLimiter.context.invalidate(ifCurrent: generation) else { return }
        generation = request
        persistLockState(true)
    }

    func endSession() {
        isActive = false
        currentStaff = nil
        _ = rateLimiter.context.invalidate(ifCurrent: generation)
    }

    func checkLockoutState() async throws(POSAuthError) {
        try await rateLimiter.checkAllowed(token: generation)
    }

    func checkpoint() async {
        // Wait, busy and stale-token results are expected; the limiter logs storage failures.
        try? await rateLimiter.checkAllowed(token: generation, checkpoint: true)
    }
}

private extension DefaultPOSAccessSession {
    /// The app target reads this on cold launch to decide whether to reopen POS
    /// (see `MainTabBarController.autoReopenPOSIfNeeded`).
    func persistLockState(_ locked: Bool) {
        userDefaults.set(locked, forKey: POSLockStateKey.key(for: siteID))
    }
}
