import Foundation

final class POSLocalRateLimiter {
    private let siteID: Int64
    private let userDefaults: UserDefaults
    private let now: () -> Date

    private static let attemptsKey = "com.woocommerce.pos.rateLimiter.failedAttempts"
    private static let lockoutUntilKey = "com.woocommerce.pos.rateLimiter.lockoutUntil"
    private static let permanentlyLockedKey = "com.woocommerce.pos.rateLimiter.permanentlyLocked"

    private struct LockoutThreshold {
        let attempts: Int
        let duration: TimeInterval?
    }

    private static let lockoutThresholds: [LockoutThreshold] = [
        LockoutThreshold(attempts: 5, duration: 30),
        LockoutThreshold(attempts: 10, duration: 300),
        LockoutThreshold(attempts: 15, duration: nil)
    ]

    init(siteID: Int64, userDefaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.siteID = siteID
        self.userDefaults = userDefaults
        self.now = now
    }

    func checkAllowed() throws(POSAuthError) {
        if isPermanentlyLocked {
            throw .permanentlyLocked
        }
        if let until = lockoutUntil, until > now() {
            throw .rateLimited(until: until)
        }
    }

    func recordFailure() {
        failedAttempts += 1
        let attempts = failedAttempts

        for threshold in Self.lockoutThresholds.reversed() where attempts >= threshold.attempts {
            if let duration = threshold.duration {
                lockoutUntil = now().addingTimeInterval(duration)
            } else {
                isPermanentlyLocked = true
            }
            break
        }
    }

    func errorForCurrentState(fallback: POSAuthError) -> POSAuthError {
        do {
            try checkAllowed()
            return fallback
        } catch {
            return error
        }
    }

    func reset() {
        failedAttempts = 0
        lockoutUntil = nil
        isPermanentlyLocked = false
    }
}

private extension POSLocalRateLimiter {
    func scopedKey(_ base: String) -> String {
        "\(base).\(siteID)"
    }

    var failedAttempts: Int {
        get { userDefaults.integer(forKey: scopedKey(Self.attemptsKey)) }
        set { userDefaults.set(newValue, forKey: scopedKey(Self.attemptsKey)) }
    }

    var lockoutUntil: Date? {
        get { userDefaults.object(forKey: scopedKey(Self.lockoutUntilKey)) as? Date }
        set { userDefaults.set(newValue, forKey: scopedKey(Self.lockoutUntilKey)) }
    }

    var isPermanentlyLocked: Bool {
        get { userDefaults.bool(forKey: scopedKey(Self.permanentlyLockedKey)) }
        set { userDefaults.set(newValue, forKey: scopedKey(Self.permanentlyLockedKey)) }
    }
}
