import Foundation
import Observation

@Observable
@MainActor
final class DefaultPOSAccessSession: POSAccessSession {
    private(set) var currentStaff: POSStaff?
    private(set) var isLocked: Bool
    private(set) var isPINProtectionEnabled: Bool
    @ObservationIgnored private(set) var accessScope = POSPINSessionTokens.Token()

    @ObservationIgnored private let credentialProvider: POSPINCredentialProviding
    @ObservationIgnored private let siteID: Int64
    @ObservationIgnored private let authenticator: POSPINAuthenticating
    @ObservationIgnored private let rateLimiter: POSLocalRateLimiter
    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private var generation: POSPINSessionTokens.Token
    @ObservationIgnored private var hasKnownProtection: Bool
    @ObservationIgnored private let onEnd: @MainActor (POSStaff?) -> Void

    init(siteID: Int64,
         authenticator: POSPINAuthenticating,
         rateLimiter: POSLocalRateLimiter,
         credentialProvider: POSPINCredentialProviding,
         userDefaults: UserDefaults = .standard,
         resumingStaff: POSStaff? = nil,
         onEnd: @escaping @MainActor (POSStaff?) -> Void = { _ in }) {
        self.credentialProvider = credentialProvider
        self.siteID = siteID
        self.authenticator = authenticator
        self.rateLimiter = rateLimiter
        self.generation = rateLimiter.sessionTokens.invalidate()
        self.userDefaults = userDefaults
        self.onEnd = onEnd
        let credentials = try? credentialProvider.credentials()
        let hasCredentials = credentials.map { !$0.isEmpty }
        self.hasKnownProtection = hasCredentials == true
        let isProtected = hasCredentials ?? true
        self.isPINProtectionEnabled = isProtected
        // Only an operator still unlocked in this app run can resume, and only while their PIN still exists.
        let resumedStaff = resumingStaff.flatMap { staff in
            credentials?.contains { $0.staff == staff } == true
                && !userDefaults.bool(forKey: POSLockStateKey.key(for: siteID)) ? staff : nil
        }
        self.currentStaff = isProtected ? resumedStaff : nil
        self.isLocked = isProtected && resumedStaff == nil
        if hasCredentials != nil { persistLockState(isLocked) }
    }

    func refreshPINProtection() throws(POSPINStoreError) {
        guard let request = rateLimiter.sessionTokens.invalidate(ifCurrent: generation) else {
            accessScope = POSPINSessionTokens.Token()
            currentStaff = nil
            isPINProtectionEnabled = true
            isLocked = true
            throw .storageFailure
        }
        generation = request
        do {
            let isProtected = try !credentialProvider.credentials().isEmpty
            hasKnownProtection = isProtected
            if isProtected != isPINProtectionEnabled {
                accessScope = POSPINSessionTokens.Token()
            }
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
            accessScope = POSPINSessionTokens.Token()
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

    func beginPINChange() -> POSPINChangeRegistration {
        rateLimiter.pendingPINChanges.begin()
    }

    func signIn(withPIN pin: String) async throws(POSAuthError) {
        let request = generation
        let staff = try await rateLimiter.authenticate(pin: pin, using: authenticator, token: request)
        guard rateLimiter.sessionTokens.isCurrent(request), !Task.isCancelled else { throw .unknown }
        accessScope = POSPINSessionTokens.Token()
        currentStaff = staff
        isLocked = false
        persistLockState(false)
    }

    func requestManagerApproval(withPIN pin: String, for requiredCapability: POSCapability) async throws(POSAuthError) {
        let request = generation
        _ = try await rateLimiter.authenticate(pin: pin, using: authenticator, capability: requiredCapability, token: request)
        guard rateLimiter.sessionTokens.isCurrent(request), !Task.isCancelled else { throw .unknown }
    }

    func lock() {
        guard isPINProtectionEnabled else { return }
        accessScope = POSPINSessionTokens.Token()
        currentStaff = nil
        isLocked = true
        guard let request = rateLimiter.sessionTokens.invalidate(ifCurrent: generation) else { return }
        generation = request
        persistLockState(true)
    }

    func endSession() {
        onEnd(isLocked ? nil : currentStaff)
        accessScope = POSPINSessionTokens.Token()
        currentStaff = nil
        _ = rateLimiter.sessionTokens.invalidate(ifCurrent: generation)
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
