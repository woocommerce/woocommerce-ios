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

    @ObservationIgnored private let authenticator: POSPINAuthenticating
    @ObservationIgnored private let rateLimiter: POSLocalRateLimiter
    @ObservationIgnored private let cache: POSStaffCache
    @ObservationIgnored private let fetcher: POSStaffFetching
    @ObservationIgnored private let siteID: Int64

    init(authenticator: POSPINAuthenticating,
         rateLimiter: POSLocalRateLimiter,
         cache: POSStaffCache,
         fetcher: POSStaffFetching,
         siteID: Int64) {
        self.authenticator = authenticator
        self.rateLimiter = rateLimiter
        self.cache = cache
        self.fetcher = fetcher
        self.siteID = siteID
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

    func checkLockoutState() throws(POSAuthError) {
        try rateLimiter.checkAllowed()
    }

    func refreshPINStatus() async {
        let capturedGeneration = cache.generation
        do {
            let fresh = try await fetcher.fetchStaff(siteID: siteID)
            cache.save(fresh, siteID: siteID, ifGenerationStill: capturedGeneration)
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
