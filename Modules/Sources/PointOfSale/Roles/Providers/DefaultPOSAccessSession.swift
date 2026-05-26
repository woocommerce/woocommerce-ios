import Foundation
import Observation
import CocoaLumberjackSwift

@Observable
@MainActor
final class DefaultPOSAccessSession: POSAccessSession {
    private(set) var currentStaff: POSStaff?
    private(set) var isLocked: Bool = true
    private(set) var hasAnyPINs: Bool = false

    @ObservationIgnored private let authenticator: POSPINAuthenticating
    @ObservationIgnored private let rateLimiter: POSLocalRateLimiter

    init(authenticator: POSPINAuthenticating, rateLimiter: POSLocalRateLimiter) {
        self.authenticator = authenticator
        self.rateLimiter = rateLimiter
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
    }

    func refreshPINStatus() async {
        do {
            hasAnyPINs = try await authenticator.hasAnyPINs()
        } catch {
            DDLogError("Failed to refresh POS PIN status: \(error)")
        }
    }
}
