import Foundation
import Observation
import CocoaLumberjackSwift

@Observable
@MainActor
final class DefaultPOSAccessSession: POSAccessSession {
    private(set) var currentStaff: POSStaff?
    private(set) var isLocked: Bool
    private(set) var hasAnyPINs: Bool

    @ObservationIgnored private let siteID: Int64
    @ObservationIgnored private let authenticator: POSPINAuthenticating
    @ObservationIgnored private let rateLimiter: POSLocalRateLimiter
    @ObservationIgnored private let cache: POSStaffCache
    @ObservationIgnored private let fetcher: POSStaffFetching
    @ObservationIgnored private let userDefaults: UserDefaults

    /// Counts how many times the staff cache has been invalidated (logout / site-switch / roles
    /// disabled). An in-flight fetch captures this before awaiting and drops its write if the count
    /// changed — so a clear that lands mid-fetch can't resurrect staff into a cache that was just
    /// emptied. Lives on the session (not the cache) because the session owns both the fetch and the
    /// clear, and is `@MainActor`-isolated.
    @ObservationIgnored private var cacheInvalidationCount = 0

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
        // Gating is cache-driven, not connection-driven: lock whenever the cached staff list has at
        // least one PIN — including offline, since the cache persists. No cached PINs (an empty
        // cache, or staff that simply have no PINs) means no gating and no lock screen.
        let hasPINs = cache.hasAnyPINs(siteID: siteID)
        self.hasAnyPINs = hasPINs
        self.isLocked = hasPINs
    }

    func allows(_ capability: POSCapability) -> Bool {
        currentStaff?.hasCapability(capability) == true
    }

    func signIn(withPIN pin: String) async throws(POSAuthError) {
        try rateLimiter.checkAllowed()

        do {
            let staff = try await authenticateAndRefreshOnMiss(pin)
            rateLimiter.reset()
            currentStaff = staff
            isLocked = false
            // A successful sign-in proves at least one PIN exists; pre-empt refreshPINStatus.
            hasAnyPINs = true
            persistLockState(false)
        } catch POSAuthError.invalidPIN {
            // A wrong PIN counts against the rate limiter; surface the lockout state if it tripped.
            // Any other POSAuthError (rateLimited, staffFetchFailed, …) propagates untouched.
            rateLimiter.recordFailure()
            throw rateLimiter.errorForCurrentState(fallback: .invalidPIN)
        }
    }

    func requestManagerApproval(withPIN pin: String, for capability: POSCapability) async throws(POSAuthError) {
        try rateLimiter.checkAllowed()
        do {
            try await verifyAndRefreshOnMiss(managerPIN: pin, authorizes: capability)
            rateLimiter.reset()
        } catch POSAuthError.invalidPIN {
            // Same as signIn: a wrong PIN feeds the rate limiter; other errors propagate untouched.
            rateLimiter.recordFailure()
            throw rateLimiter.errorForCurrentState(fallback: .invalidPIN)
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
        do {
            try await fetchAndCacheStaff()
        } catch POSStaffFetchError.endpointUnavailable {
            // The /wc/pos/v1/staff route is absent when POS roles are disabled server-side; drop any
            // cached staff so access degrades to no PIN gating rather than locking everyone out.
            invalidateCache()
        } catch {
            // adminMissingCapability / transient / malformedResponse: leave the cache as-is and let
            // gating reflect whatever it already holds (no cached PINs ⇒ no lock screen).
            DDLogError("POS staff refresh failed: \(error)")
        }
        applyCacheState()
    }

    func clearStaffCache() {
        invalidateCache()
        currentStaff = nil
        applyCacheState()
    }
}

private extension DefaultPOSAccessSession {
    func authenticateAndRefreshOnMiss(_ pin: String) async throws(POSAuthError) -> POSStaff {
        do {
            return try await authenticator.authenticate(withPIN: pin)
        } catch POSAuthError.invalidPIN {
            // PIN absent from the (possibly stale) cache — refresh once, then retry before giving up.
            // Any other POSAuthError propagates untouched.
            try await refreshStaffCache()
            return try await authenticator.authenticate(withPIN: pin)
        }
    }

    func verifyAndRefreshOnMiss(managerPIN pin: String, authorizes capability: POSCapability) async throws(POSAuthError) {
        do {
            try await authenticator.verify(managerPIN: pin, authorizes: capability)
        } catch POSAuthError.invalidPIN {
            // Same refresh-once-then-retry as authenticate; other errors propagate untouched.
            try await refreshStaffCache()
            try await authenticator.verify(managerPIN: pin, authorizes: capability)
        }
    }

    /// Refresh-on-miss helper: fetches and caches staff, surfacing any fetch failure as
    /// `.staffFetchFailed` so the sign-in / approval flow can fail cleanly.
    func refreshStaffCache() async throws(POSAuthError) {
        do {
            try await fetchAndCacheStaff()
        } catch {
            throw .staffFetchFailed(error)
        }
    }

    /// Fetches the staff list and writes it to the cache, unless a `clear` (logout / site-switch)
    /// invalidated the cache while the fetch was in flight — in which case the write is dropped so
    /// we don't restore staff into a cache that was just emptied.
    func fetchAndCacheStaff() async throws(POSStaffFetchError) {
        let invalidationCountBeforeFetch = cacheInvalidationCount
        let staff = try await fetcher.fetchStaff(siteID: siteID)
        // Drop the write if the cache was invalidated (e.g. logout) while the fetch was in flight.
        guard invalidationCountBeforeFetch == cacheInvalidationCount else { return }
        cache.save(staff, siteID: siteID)
    }

    /// Empties the cache and bumps the invalidation count so any in-flight fetch's write is dropped.
    func invalidateCache() {
        cacheInvalidationCount &+= 1
        cache.clear(siteID: siteID)
    }
}

private extension DefaultPOSAccessSession {
    /// Re-derives gating from the cache. Locks only when the cached staff list has PINs and nobody
    /// is signed in; an empty (or PIN-free) cache unlocks, so the lock screen never shows for it.
    func applyCacheState() {
        hasAnyPINs = cache.hasAnyPINs(siteID: siteID)
        if hasAnyPINs {
            // Don't override a session that's already signed in or was manually locked.
            if currentStaff == nil {
                isLocked = true
            }
        } else {
            isLocked = false
        }
        // Keep the persisted key in sync: the app target reads it on cold launch to decide whether
        // to auto-reopen POS (see MainTabBarController.autoReopenPOSIfNeeded).
        persistLockState(isLocked)
    }
}

private extension DefaultPOSAccessSession {
    func persistLockState(_ locked: Bool) {
        userDefaults.set(locked, forKey: POSLockStateKey.key(for: siteID))
    }
}
