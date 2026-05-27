import Foundation
import Observation
import CocoaLumberjackSwift

@Observable
@MainActor
final class DefaultPOSAccessSession: POSAccessSession {
    private(set) var currentStaff: POSStaff?
    private(set) var isLocked: Bool = true
    private(set) var hasAnyPINs: Bool = false
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
            hasAnyPINs = cache.hasAnyPINs(siteID: siteID)
            return
        }
        do {
            let fresh = try await fetcher.fetchStaff(siteID: siteID)
            cache.save(fresh, siteID: siteID)
            hasAnyPINs = cache.hasAnyPINs(siteID: siteID)
            flagDisabledServerSide = false
            if !hasAnyPINs {
                isLocked = false
            }
        } catch let error as POSStaffFetchError {
            switch error {
            case .flagDisabledServerSide:
                cache.clear(siteID: siteID)
                hasAnyPINs = false
                flagDisabledServerSide = true
                isLocked = false
            case .adminMissingCapability, .transient, .malformedResponse:
                DDLogError("POS staff refresh failed: \(error)")
                hasAnyPINs = cache.hasAnyPINs(siteID: siteID)
            }
        } catch {
            DDLogError("POS staff refresh failed: \(error)")
        }
    }

    func clearStaffCache() {
        cache.clear(siteID: siteID)
        hasAnyPINs = false
        currentStaff = nil
        isLocked = true
        flagDisabledServerSide = false
    }
}
