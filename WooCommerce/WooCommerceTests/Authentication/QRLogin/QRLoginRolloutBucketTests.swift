import Foundation
import Testing
@testable import WooCommerce

struct QRLoginRolloutBucketTests {

    @Test func bucket_when_first_read_then_persists_random_value() {
        // Given
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let bucket = QRLoginRolloutBucket(userDefaults: defaults, randomBucketProvider: { 7 })

        // When
        let first = bucket.bucket
        let second = bucket.bucket

        // Then
        #expect(first == 7)
        #expect(second == 7)
    }

    @Test func bucket_when_already_persisted_then_returns_stored_value() {
        // Given
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(3, forKey: "qr_login_rollout_bucket")
        let bucket = QRLoginRolloutBucket(userDefaults: defaults, randomBucketProvider: { 9 })

        // When
        let value = bucket.bucket

        // Then
        #expect(value == 3)
    }

    @Test func bucket_when_persisted_value_is_out_of_range_then_regenerates() {
        // Given — defensive: out-of-range value (e.g. from a future schema)
        // should be treated as missing.
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(99, forKey: "qr_login_rollout_bucket")
        let bucket = QRLoginRolloutBucket(userDefaults: defaults, randomBucketProvider: { 4 })

        // When
        let value = bucket.bucket

        // Then
        #expect(value == 4)
    }

    @Test func isEnabled_when_bucket_is_1_then_true() {
        // Given
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let bucket = QRLoginRolloutBucket(userDefaults: defaults, randomBucketProvider: { 1 })

        // Then
        #expect(bucket.isEnabled == true)
    }

    @Test func isEnabled_when_bucket_is_2_then_false() {
        // Given — only bucket 1 of 10 is enabled (10% rollout).
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let bucket = QRLoginRolloutBucket(userDefaults: defaults, randomBucketProvider: { 2 })

        // Then
        #expect(bucket.isEnabled == false)
    }
}
