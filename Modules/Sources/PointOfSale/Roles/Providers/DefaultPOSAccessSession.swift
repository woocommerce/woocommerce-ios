import Foundation
import Observation

@Observable
@MainActor
final class DefaultPOSAccessSession: POSAccessSession {
    private(set) var currentStaff: POSStaff?
    private(set) var isLocked: Bool = true
    private(set) var hasAnyPINs: Bool = false

    @ObservationIgnored private let siteID: Int64
    @ObservationIgnored private let authenticator: POSPINAuthenticating
    @ObservationIgnored private let rateLimiter: POSLocalRateLimiter
    @ObservationIgnored private let userDefaults: UserDefaults

    init(siteID: Int64,
         authenticator: POSPINAuthenticating,
         rateLimiter: POSLocalRateLimiter,
         userDefaults: UserDefaults = .standard) {
        self.siteID = siteID
        self.authenticator = authenticator
        self.rateLimiter = rateLimiter
        self.userDefaults = userDefaults
    }

    func allows(_ capability: POSCapability) -> Bool {
        currentStaff?.hasCapability(capability) == true
    }

    func signIn(withPIN pin: String) async throws(POSAuthError) {
        try rateLimiter.checkAllowed()

        do {
            let staff = try await authenticator.authenticate(withPIN: pin)
            rateLimiter.reset()
            currentStaff = staff
            isLocked = false
            // A successful sign-in proves at least one PIN exists.
            hasAnyPINs = true
            persistLockState(false)
        } catch {
            switch error {
            case .invalidPIN:
                rateLimiter.recordFailure()
                throw rateLimiter.errorForCurrentState(fallback: .invalidPIN)
            default:
                throw error
            }
        }
    }

    func requestManagerApproval(withPIN pin: String, for capability: POSCapability) async throws(POSAuthError) {
        // TODO: implement when the manager override flow is wired in.
        throw .unknown
    }

    func lock() {
        isLocked = true
        persistLockState(true)
    }

    func checkLockoutState() throws(POSAuthError) {
        try rateLimiter.checkAllowed()
    }

    func refreshPINStatus() async {
        // No-op until the session owns staff fetching and can derive PIN presence from the cached
        // staff list. Until then, `hasAnyPINs` is set by a successful sign-in.
    }
}

private extension DefaultPOSAccessSession {
    func persistLockState(_ locked: Bool) {
        userDefaults.set(locked, forKey: POSLockStateKey.key(for: siteID))
    }
}
