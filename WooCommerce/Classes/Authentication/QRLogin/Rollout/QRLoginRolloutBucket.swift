import Foundation

/// Per-install, persisted random bucket in `1...10` for QR-login rollout.
///
/// Spec §2.1: each install is assigned a number on first read so the decision
/// is stable across restarts. The currently-enabled range (`1...1`) maps to a
/// 10% rollout. Debug overrides bypass the bucket check entirely — they're not
/// the bucket's concern; see `QRLoginAvailability`.
struct QRLoginRolloutBucket {

    private static let bucketKey = "qr_login_rollout_bucket"
    private static let bucketRange: ClosedRange<Int> = 1...10
    private static let enabledBuckets: ClosedRange<Int> = 1...1

    private let userDefaults: UserDefaults
    private let randomBucketProvider: () -> Int

    init(userDefaults: UserDefaults = .standard,
         randomBucketProvider: @escaping () -> Int = { Int.random(in: QRLoginRolloutBucket.bucketRange) }) {
        self.userDefaults = userDefaults
        self.randomBucketProvider = randomBucketProvider
    }

    /// Returns the persisted bucket, generating + persisting one on first read.
    var bucket: Int {
        if let stored = userDefaults.object(forKey: Self.bucketKey) as? Int,
           Self.bucketRange.contains(stored) {
            return stored
        }
        let fresh = randomBucketProvider()
        userDefaults.set(fresh, forKey: Self.bucketKey)
        return fresh
    }

    /// `true` when this install's bucket is inside the currently enabled range.
    var isEnabled: Bool {
        Self.enabledBuckets.contains(bucket)
    }
}
