import Foundation
import UIKit
import enum Experiments.FeatureFlag

@MainActor
enum POSAccessSessionFactory {
    private static var rateLimiters: [Int64: POSLocalRateLimiter] = [:]
    /// In memory only: a relaunch never resumes an operator, so POS opens locked after the app is killed.
    private static var unlockedStaff: [Int64: RetainedStaff] = [:]
    private static var isAppInBackground = false
    private static let lifecycleObservers = [
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated {
                isAppInBackground = true
                unlockedStaff = unlockedStaff.filter { siteID, retained in
                    !POSLockSettings(siteID: siteID, userDefaults: retained.userDefaults).preferences.locksInBackground
                }
            }
        },
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { isAppInBackground = false }
        }
    ]

    private struct RetainedStaff {
        let staff: POSStaff
        let endedAt: Date
        let userDefaults: UserDefaults
    }

    static func make(siteID: Int64,
                     featureFlags: POSFeatureFlagProviding,
                     credentialProvider: POSPINCredentialProviding? = nil,
                     rateLimiter: POSLocalRateLimiter? = nil,
                     userDefaults: UserDefaults = .standard,
                     locksWhenPOSOpens: Bool = true,
                     now: @escaping @MainActor () -> Date = Date.init,
                     shouldCreate: @MainActor () -> Bool = { true }) async throws -> POSAccessSession {
        guard featureFlags.isFeatureFlagEnabled(.pointOfSaleRoles) else {
            return UnrestrictedPOSAccessSession()
        }
        _ = lifecycleObservers
        let credentialProvider = credentialProvider ?? POSLocalPINStore(siteID: siteID)
        let limiter: POSLocalRateLimiter
        if let rateLimiter {
            limiter = rateLimiter
        } else {
            if let current = rateLimiters[siteID], !current.isRetired {
                limiter = current
            } else {
                // A retired limiter means the PIN setup was cleared, for example on logout.
                limiter = POSLocalRateLimiter(siteID: siteID)
                rateLimiters[siteID] = limiter
                unlockedStaff[siteID] = nil
            }
        }
        try await limiter.pendingPINChanges.waitUntilEmpty()
        try Task.checkCancellation()
        guard shouldCreate() else { throw CancellationError() }
        let preferences = POSLockSettings(siteID: siteID, userDefaults: userDefaults).preferences
        let retained = unlockedStaff.removeValue(forKey: siteID)
        let resumingStaff = retained.flatMap { retained -> POSStaff? in
            if isAppInBackground && preferences.locksInBackground { return nil }
            if let timeout = preferences.inactivityTimeout.interval {
                let elapsed = now().timeIntervalSince(retained.endedAt)
                guard elapsed >= 0, elapsed < timeout else { return nil }
            }
            return retained.staff
        }
        return DefaultPOSAccessSession(
            siteID: siteID,
            authenticator: DefaultPOSPINAuthenticator(credentialProvider: credentialProvider),
            rateLimiter: limiter,
            credentialProvider: credentialProvider,
            userDefaults: userDefaults,
            resumingStaff: locksWhenPOSOpens ? nil : resumingStaff,
            onEnd: { staff in
                let preferences = POSLockSettings(siteID: siteID, userDefaults: userDefaults).preferences
                // Cleanup can finish after the background notification has already cleared the cache.
                guard let staff, !isAppInBackground || !preferences.locksInBackground else {
                    unlockedStaff[siteID] = nil
                    return
                }
                unlockedStaff[siteID] = RetainedStaff(staff: staff, endedAt: now(), userDefaults: userDefaults)
            }
        )
    }

    /// Stops the operator of an ended session from resuming on the next POS visit,
    /// without persisting a lock that would make the app reopen POS on cold launch.
    static func forgetUnlockedStaff(siteID: Int64) {
        unlockedStaff[siteID] = nil
    }
}
