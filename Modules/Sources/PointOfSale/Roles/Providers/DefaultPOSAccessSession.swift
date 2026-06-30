import Foundation
import Observation
import CocoaLumberjackSwift
import struct Yosemite.POSStaffMember

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

    /// Upper bound on how long the interactive refresh-on-miss staff fetch may block a sign-in or
    /// manager-approval attempt. Without it, an unresponsive staff endpoint freezes the PIN screen on
    /// its loading state indefinitely; on timeout the attempt fails with a transient error so the
    /// keypad re-enables and the operator can retry.
    @ObservationIgnored private let staffRefreshTimeout: TimeInterval

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
         userDefaults: UserDefaults = .standard,
         staffRefreshTimeout: TimeInterval = Constants.defaultStaffRefreshTimeout) {
        self.siteID = siteID
        self.authenticator = authenticator
        self.rateLimiter = rateLimiter
        self.cache = cache
        self.fetcher = fetcher
        self.userDefaults = userDefaults
        self.staffRefreshTimeout = staffRefreshTimeout
        // Gating is cache-driven, not connection-driven: lock whenever the cached staff list has at
        // least one PIN — including offline, since the cache persists. No cached PINs (an empty
        // cache, or staff that simply have no PINs) means no gating and no lock screen.
        let hasPINs = cache.hasAnyPINs(siteID: siteID)
        self.hasAnyPINs = hasPINs
        self.isLocked = hasPINs
    }

    func allows(_ capability: POSCapability) -> Bool {
        // Access is only gated when the cached staff list has PINs — the same cache-driven signal that
        // drives the lock screen. With no PIN-backed staff, nobody signs in (so `currentStaff` is nil)
        // and there'd be no PIN to approve an override, so gating is effectively off and everything is
        // allowed. Without this, a roles-enabled site that hasn't set up any PINs would deny every gated
        // action and strand the operator on an override modal no one can satisfy.
        guard hasAnyPINs else {
            return true
        }
        return currentStaff?.hasCapability(capability) == true
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

    func requestManagerApproval(withPIN pin: String, for capability: POSCapability) async throws(POSAuthError) -> POSStaff? {
        try rateLimiter.checkAllowed()
        do {
            let staff = try await verifyAndRefreshOnMiss(managerPIN: pin, authorizes: capability)
            rateLimiter.reset()
            return staff
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

    /// Refreshes gating from a staff list the caller already fetched — caches it and re-derives lock
    /// state without a second staff fetch.
    func refreshPINStatus(using staff: [POSStaffMember]) async {
        cache.save(staff, siteID: siteID)
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

    func verifyAndRefreshOnMiss(managerPIN pin: String, authorizes capability: POSCapability) async throws(POSAuthError) -> POSStaff {
        do {
            return try await authenticator.verify(managerPIN: pin, authorizes: capability)
        } catch POSAuthError.invalidPIN {
            // Same refresh-once-then-retry as authenticate; other errors propagate untouched.
            try await refreshStaffCache()
            return try await authenticator.verify(managerPIN: pin, authorizes: capability)
        }
    }

    /// Refresh-on-miss helper: fetches and caches staff, surfacing any fetch failure as
    /// `.staffFetchFailed` so the sign-in / approval flow can fail cleanly. The fetch is bounded by
    /// `staffRefreshTimeout` so an unresponsive staff endpoint can't freeze the interactive PIN screen
    /// on its loading state — a timeout degrades to a transient fetch failure and the keypad recovers.
    func refreshStaffCache() async throws(POSAuthError) {
        do {
            try await withTimeout(seconds: staffRefreshTimeout) { [self] in
                try await fetchAndCacheStaff()
            }
        } catch let error as POSStaffFetchError {
            throw .staffFetchFailed(error)
        } catch {
            // A timeout (or cancellation) of the fetch — treat it like any other transient failure so
            // the operator sees an error and can retry instead of staring at a stuck loading state.
            throw .staffFetchFailed(.transient(retryable: true))
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

extension DefaultPOSAccessSession {
    enum Constants {
        /// Default ceiling for the interactive refresh-on-miss staff fetch. Long enough to absorb a
        /// slow-but-working endpoint, short enough that an unresponsive one doesn't strand the operator
        /// on the loading state.
        static let defaultStaffRefreshTimeout: TimeInterval = 10
    }
}

/// Races `operation` against a timeout, throwing `POSStaffRefreshTimeout` if the deadline wins. The
/// losing child task is cancelled, so a timed-out fetch stops cooperatively (and its `Task.sleep`
/// unwinds) rather than leaking.
private func withTimeout<T: Sendable>(
    seconds: TimeInterval,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * Double(NSEC_PER_SEC)))
            throw POSStaffRefreshTimeout()
        }
        defer { group.cancelAll() }
        guard let result = try await group.next() else {
            throw POSStaffRefreshTimeout()
        }
        return result
    }
}

private struct POSStaffRefreshTimeout: Error {}
