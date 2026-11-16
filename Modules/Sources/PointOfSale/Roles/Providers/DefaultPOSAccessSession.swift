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
    @ObservationIgnored private let rateLimiter: POSLocalRateLimiter
    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private var generation: POSPINSessionTokens.Token
    @ObservationIgnored private var hasKnownProtection: Bool

    init(siteID: Int64,
         authenticator: POSPINAuthenticating,
         rateLimiter: POSLocalRateLimiter,
         credentialProvider: POSPINCredentialProviding,
         userDefaults: UserDefaults = .standard) {
        self.credentialProvider = credentialProvider
        self.siteID = siteID
        self.authenticator = authenticator
        self.rateLimiter = rateLimiter
        self.generation = rateLimiter.sessionTokens.invalidate()
        self.userDefaults = userDefaults
        let hasCredentials = try? !credentialProvider.credentials().isEmpty
        self.hasKnownProtection = hasCredentials == true
        let isProtected = hasCredentials ?? true
        self.isPINProtectionEnabled = isProtected
        self.isLocked = isProtected
        if let hasCredentials { persistLockState(hasCredentials) }
    }

    func refreshPINProtection() throws(POSPINStoreError) {
        guard let request = rateLimiter.sessionTokens.invalidate(ifCurrent: generation) else {
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
        guard rateLimiter.sessionTokens.isCurrent(generation) else { return false }
        // Without an Admin PIN there is nobody to sign in or approve, so every action is allowed.
        guard isPINProtectionEnabled else {
            return true
        }
        return currentStaff?.hasCapability(capability) == true
    }

    func signIn(withPIN pin: String) async throws(POSAuthError) {
        let request = generation
        let staff = try await rateLimiter.authenticate(pin: pin, using: authenticator, token: request)
        guard rateLimiter.sessionTokens.isCurrent(request), !Task.isCancelled else { throw .unknown }
        currentStaff = staff
        isLocked = false
        persistLockState(false)
    }

    func requestManagerApproval(withPIN pin: String, for capability: POSCapability) async throws(POSAuthError) {
        let request = generation
        _ = try await rateLimiter.authenticate(pin: pin, using: authenticator, capability: capability, token: request)
        guard rateLimiter.sessionTokens.isCurrent(request), !Task.isCancelled else { throw .unknown }
    }

    func lock() {
        guard isPINProtectionEnabled else { return }
        currentStaff = nil
        isLocked = true
        guard let request = rateLimiter.sessionTokens.invalidate(ifCurrent: generation) else { return }
        generation = request
        persistLockState(true)
    }

    func checkLockoutState() async throws(POSAuthError) {
        try await rateLimiter.checkAllowed(token: generation)
    }

    func saveElapsedTime() async {
        await rateLimiter.saveElapsedTime(token: generation)
    }
}

private extension DefaultPOSAccessSession {
    /// The app target reads this on cold launch to decide whether to reopen POS
    /// (see `MainTabBarController.autoReopenPOSIfNeeded`).
    func persistLockState(_ locked: Bool) {
        userDefaults.set(locked, forKey: POSLockStateKey.key(for: siteID))
    }
}
