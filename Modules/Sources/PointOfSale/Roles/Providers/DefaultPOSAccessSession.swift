import Foundation
import Observation

@Observable
@MainActor
final class DefaultPOSAccessSession: POSAccessSession {
    private(set) var currentStaff: POSStaff?
    private(set) var isLocked: Bool
    let isPINProtectionEnabled: Bool

    @ObservationIgnored private let siteID: Int64
    @ObservationIgnored private let authenticator: POSPINAuthenticating
    @ObservationIgnored private let rateLimiter: POSLocalRateLimiter
    @ObservationIgnored private let userDefaults: UserDefaults

    init(siteID: Int64,
         authenticator: POSPINAuthenticating,
         rateLimiter: POSLocalRateLimiter,
         credentialProvider: POSPINCredentialProviding,
         userDefaults: UserDefaults = .standard) {
        self.siteID = siteID
        self.authenticator = authenticator
        self.rateLimiter = rateLimiter
        self.userDefaults = userDefaults
        let hasCredentials = try? !credentialProvider.credentials().isEmpty
        let isProtected = hasCredentials ?? true
        self.isPINProtectionEnabled = isProtected
        self.isLocked = isProtected
        // An unreadable store keeps this session locked but doesn't make the app reopen POS on launch,
        // so a lasting read failure can't trap the device behind a lock that no PIN opens.
        persistLockState(hasCredentials ?? false)
    }

    func allows(_ capability: POSCapability) -> Bool {
        // Without an Admin PIN there is nobody to sign in or approve, so every action is allowed.
        guard isPINProtectionEnabled else {
            return true
        }
        return currentStaff?.hasCapability(capability) == true
    }

    func signIn(withPIN pin: String) async throws(POSAuthError) {
        try rateLimiter.checkAllowed()

        do {
            let staff = try await authenticator.authenticate(withPIN: pin)
            rateLimiter.reset()
            currentStaff = staff
            isLocked = false
            persistLockState(false)
        } catch POSAuthError.invalidPIN {
            // A wrong PIN counts against the rate limiter; surface the lockout state if it tripped.
            // Any other POSAuthError propagates untouched.
            rateLimiter.recordFailure()
            throw rateLimiter.errorForCurrentState(fallback: .invalidPIN)
        }
    }

    func requestManagerApproval(withPIN pin: String, for capability: POSCapability) async throws(POSAuthError) {
        try rateLimiter.checkAllowed()
        do {
            try await authenticator.verify(managerPIN: pin, authorizes: capability)
            rateLimiter.reset()
        } catch POSAuthError.invalidPIN {
            // Same as signIn: a wrong PIN feeds the rate limiter; other errors propagate untouched.
            rateLimiter.recordFailure()
            throw rateLimiter.errorForCurrentState(fallback: .invalidPIN)
        }
    }

    func lock() {
        guard isPINProtectionEnabled else { return }
        isLocked = true
        persistLockState(true)
    }

    func checkLockoutState() throws(POSAuthError) {
        try rateLimiter.checkAllowed()
    }
}

private extension DefaultPOSAccessSession {
    /// The app target reads this on cold launch to decide whether to reopen POS
    /// (see `MainTabBarController.autoReopenPOSIfNeeded`).
    func persistLockState(_ locked: Bool) {
        userDefaults.set(locked, forKey: POSLockStateKey.key(for: siteID))
    }
}
