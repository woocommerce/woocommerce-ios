import Foundation
import Observation
import CocoaLumberjackSwift

@Observable
@MainActor
final class DefaultPOSAccessSession: POSAccessSession {
    private(set) var currentStaff: POSStaff?
    private(set) var isLocked: Bool = true
    private(set) var pinStatus: POSPINStatus = .unknown
    private(set) var flagDisabledServerSide: Bool = false

    @ObservationIgnored private let siteID: Int64
    @ObservationIgnored private let authenticator: POSPINAuthenticating
    @ObservationIgnored private let rateLimiter: POSLocalRateLimiter
    @ObservationIgnored private let cache: POSStaffCache
    @ObservationIgnored private let fetcher: POSStaffFetching
    @ObservationIgnored private let userDefaults: UserDefaults

    init(siteID: Int64,
         authenticator: POSPINAuthenticating,
         rateLimiter: POSLocalRateLimiter,
         cache: POSStaffCache,
         fetcher: POSStaffFetching,
         userDefaults: UserDefaults = .standard) {
        self.siteID = siteID
        self.authenticator = authenticator
        self.rateLimiter = rateLimiter
        self.cache = cache
        self.fetcher = fetcher
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
            // Sign-in proves a PIN exists; pre-empt refreshPINStatus.
            pinStatus = .present
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

    @discardableResult
    func requestManagerApproval(withPIN pin: String, for capability: POSCapability) async throws(POSAuthError) -> POSStaff {
        try rateLimiter.checkAllowed()
        do {
            let approver = try await authenticator.verify(managerPIN: pin, authorizes: capability)
            rateLimiter.reset()
            return approver
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

    func lock() {
        isLocked = true
        persistLockState(true)
    }

    func checkLockoutState() throws(POSAuthError) {
        try rateLimiter.checkAllowed()
    }

    func refreshPINStatus() async {
        let capturedGeneration = cache.generation
        do {
            let fresh = try await fetcher.fetchStaff(siteID: siteID)
            guard cache.save(fresh, siteID: siteID, ifGenerationStill: capturedGeneration) else { return }
            flagDisabledServerSide = false
            applyCachedPINStatus()
        } catch let error as POSStaffFetchError {
            switch error {
            case .flagDisabledServerSide:
                cache.clear(siteID: siteID)
                flagDisabledServerSide = true
                pinStatus = .absent
                isLocked = false
            case .adminMissingCapability, .transient, .malformedResponse:
                DDLogError("POS staff refresh failed: \(error)")
                // Stay .unknown without a cached fetch - otherwise an offline first-open
                // would auto-unlock without ever verifying staff.
                if cache.lastFetched(siteID: siteID) != nil {
                    applyCachedPINStatus()
                }
            }
        } catch {
            DDLogError("POS staff refresh failed: \(error)")
        }
    }

    func clearStaffCache() {
        cache.clear(siteID: siteID)
        pinStatus = .unknown
        currentStaff = nil
        isLocked = true
        flagDisabledServerSide = false
    }
}

private extension DefaultPOSAccessSession {
    func applyCachedPINStatus() {
        if cache.hasAnyPINs(siteID: siteID) {
            pinStatus = .present
        } else {
            pinStatus = .absent
            isLocked = false
        }
    }
}

private extension DefaultPOSAccessSession {
    func persistLockState(_ locked: Bool) {
        userDefaults.set(locked, forKey: POSLockStateKey.key(for: siteID))
    }
}
