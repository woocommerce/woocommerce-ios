import Foundation
import Observation
import CocoaLumberjackSwift

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
            // A successful sign-in proves at least one PIN exists, so update the
            // cached flag eagerly. Without this, a still-pending refreshPINStatus
            // could leave hasAnyPINs == false, which would later short-circuit
            // both the tracker's timer-fire and the background-lock observer.
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
        do {
            hasAnyPINs = try await authenticator.hasAnyPINs()
        } catch {
            DDLogError("Failed to refresh POS PIN status: \(error)")
        }
    }
}

private extension DefaultPOSAccessSession {
    func persistLockState(_ locked: Bool) {
        userDefaults.set(locked, forKey: POSLockStateKey.key(for: siteID))
    }
}
