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
    @ObservationIgnored private let now: @Sendable () -> Date

    private static let refreshTTL: TimeInterval = 30

    init(authenticator: POSPINAuthenticating,
         rateLimiter: POSLocalRateLimiter,
         cache: POSStaffCache,
         fetcher: POSStaffFetching,
         siteID: Int64,
         now: @escaping @Sendable () -> Date = Date.init) {
        self.authenticator = authenticator
        self.rateLimiter = rateLimiter
        self.cache = cache
        self.fetcher = fetcher
        self.siteID = siteID
        self.now = now
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
        if let last = cache.lastFetched(siteID: siteID),
           now().timeIntervalSince(last) < Self.refreshTTL {
            applyCachedPINStatus()
            return
        }
        do {
            let fresh = try await fetcher.fetchStaff(siteID: siteID)
            cache.save(fresh, siteID: siteID)
            flagDisabledServerSide = false
            applyCachedPINStatus()
        } catch let error as POSStaffFetchError {
            switch error {
            case .flagDisabledServerSide:
                cache.clear(siteID: siteID)
                flagDisabledServerSide = true
                // Server authoritatively says there's no PIN system here, so unlock.
                pinStatus = .absent
                isLocked = false
            case .adminMissingCapability, .transient, .malformedResponse:
                DDLogError("POS staff refresh failed: \(error)")
                // Fall back to last-known-good cache only if there is one. A cold cache plus
                // a refresh failure must stay `.unknown` so the overlay keeps the boundary up;
                // otherwise an offline first-open would auto-unlock with no verification.
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
    /// Translates the cache state into `pinStatus` and unlocks the session if we've confirmed
    /// there are no PINs to enforce against. Used by the TTL early-return, the post-fetch path,
    /// and the cache-fallback arm so all three derive `pinStatus` the same way.
    func applyCachedPINStatus() {
        if cache.hasAnyPINs(siteID: siteID) {
            pinStatus = .present
        } else {
            pinStatus = .absent
            isLocked = false
        }
    }
}
