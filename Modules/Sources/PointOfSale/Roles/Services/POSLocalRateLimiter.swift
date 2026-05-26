import Foundation
import enum Networking.POSAuthError

/// Rate limiter for local POS PIN authentication, matching the backend's POSRateLimitService thresholds.
///
/// Progressive lockouts persisted in UserDefaults so killing the app doesn't reset the counter:
/// - 5 failed attempts: 30-second lockout
/// - 10 failed attempts: 5-minute lockout
/// - 15 failed attempts: permanent lock (only recovery is logout)
///
/// A successful PIN entry resets the counter. Logout also resets it.
public final class POSLocalRateLimiter {

    public init() {}

    // MARK: - Thresholds (matching backend POSRateLimitService)

    private static let lockoutThresholds: [(attempts: Int, duration: TimeInterval?)] = [
        (5, 30),
        (10, 300),
        (15, nil)   // nil = permanent
    ]

    // MARK: - UserDefaults Keys

    private static let attemptsKey = "com.woocommerce.pos.rateLimiter.failedAttempts"
    private static let lockoutUntilKey = "com.woocommerce.pos.rateLimiter.lockoutUntil"
    private static let permanentlyLockedKey = "com.woocommerce.pos.rateLimiter.permanentlyLocked"

    // MARK: - State

    private var failedAttempts: Int {
        get { UserDefaults.standard.integer(forKey: Self.attemptsKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.attemptsKey) }
    }

    private var lockoutUntil: Date? {
        get { UserDefaults.standard.object(forKey: Self.lockoutUntilKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: Self.lockoutUntilKey) }
    }

    public var isPermanentlyLocked: Bool {
        get { UserDefaults.standard.bool(forKey: Self.permanentlyLockedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.permanentlyLockedKey) }
    }

    // MARK: - API

    /// Checks if PIN entry is currently allowed.
    /// Throws `POSAuthError.rateLimited` if in a lockout period.
    public func checkAllowed() throws {
        if isPermanentlyLocked {
            throw POSAuthError.rateLimited(retryAfter: -1)
        }
        if let until = lockoutUntil {
            let remaining = Int(until.timeIntervalSinceNow)
            if remaining > 0 {
                throw POSAuthError.rateLimited(retryAfter: remaining)
            }
            // Lockout expired, clear it
            lockoutUntil = nil
        }
    }

    /// Records a failed PIN attempt and applies lockout if a threshold is crossed.
    public func recordFailure() {
        failedAttempts += 1
        let attempts = failedAttempts

        // Check thresholds in reverse (highest first)
        for threshold in Self.lockoutThresholds.reversed() {
            if attempts >= threshold.attempts {
                if let duration = threshold.duration {
                    lockoutUntil = Date().addingTimeInterval(duration)
                } else {
                    isPermanentlyLocked = true
                }
                break
            }
        }
    }

    /// Returns the appropriate error after a failed attempt.
    /// If a lockout was just triggered by `recordFailure()`, returns the lockout error.
    /// Otherwise returns the fallback error (e.g. invalidPIN).
    public func errorForCurrentState(fallback: POSAuthError) throws -> POSAuthError {
        do {
            try checkAllowed()
            return fallback
        } catch let error as POSAuthError {
            return error
        }
    }

    /// Resets the rate limiter. Called on successful PIN entry or logout.
    public func reset() {
        failedAttempts = 0
        lockoutUntil = nil
        isPermanentlyLocked = false
    }
}
