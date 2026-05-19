import Foundation
import Testing
import Yosemite
import protocol Networking.RemoteFeatureFlagOverrideStore
@testable import WooCommerce

@MainActor
struct QRLoginAvailabilityTests {

    // MARK: - Prologue gating (§2.1)

    @Test func isAvailableForPrologue_when_flag_on_and_bucket_enabled_and_camera_available_then_true() async {
        // Given
        let stores = makeStores(remoteFlag: true)
        let availability = QRLoginAvailability(stores: stores,
                                               overrideStore: nil,
                                               rolloutBucket: makeBucket(value: 1),
                                               isCameraAvailable: { true })

        // When
        let enabled = await availability.isAvailableForPrologue()

        // Then
        #expect(enabled == true)
    }

    @Test func isAvailableForPrologue_when_flag_off_then_false() async {
        // Given
        let stores = makeStores(remoteFlag: false)
        let availability = QRLoginAvailability(stores: stores,
                                               overrideStore: nil,
                                               rolloutBucket: makeBucket(value: 1),
                                               isCameraAvailable: { true })

        // When
        let enabled = await availability.isAvailableForPrologue()

        // Then
        #expect(enabled == false)
    }

    @Test func isAvailableForPrologue_when_bucket_disabled_then_false() async {
        // Given
        let stores = makeStores(remoteFlag: true)
        let availability = QRLoginAvailability(stores: stores,
                                               overrideStore: nil,
                                               rolloutBucket: makeBucket(value: 5),
                                               isCameraAvailable: { true })

        // When
        let enabled = await availability.isAvailableForPrologue()

        // Then
        #expect(enabled == false)
    }

    @Test func isAvailableForPrologue_when_no_camera_then_false() async {
        // Given
        let stores = makeStores(remoteFlag: true)
        let availability = QRLoginAvailability(stores: stores,
                                               overrideStore: nil,
                                               rolloutBucket: makeBucket(value: 1),
                                               isCameraAvailable: { false })

        // When
        let enabled = await availability.isAvailableForPrologue()

        // Then
        #expect(enabled == false)
    }

    @Test func isAvailableForPrologue_when_debug_override_true_then_bypasses_bucket() async {
        // Given — override true → bucket not consulted.
        let stores = makeStores(remoteFlag: false)
        let override = StubOverrideStore(value: true)
        let availability = QRLoginAvailability(stores: stores,
                                               overrideStore: override,
                                               rolloutBucket: makeBucket(value: 9),
                                               isCameraAvailable: { true })

        // When
        let enabled = await availability.isAvailableForPrologue()

        // Then
        #expect(enabled == true)
    }

    @Test func isAvailableForPrologue_when_debug_override_false_then_disabled_regardless_of_flag() async {
        // Given
        let stores = makeStores(remoteFlag: true)
        let override = StubOverrideStore(value: false)
        let availability = QRLoginAvailability(stores: stores,
                                               overrideStore: override,
                                               rolloutBucket: makeBucket(value: 1),
                                               isCameraAvailable: { true })

        // When
        let enabled = await availability.isAvailableForPrologue()

        // Then
        #expect(enabled == false)
    }

    // MARK: - Deep-link gating (§2.2)

    @Test func isAvailableForDeepLink_when_flag_on_then_true_even_if_bucket_disabled_and_camera_unavailable() async {
        // Given — deep-link bypasses the bucket and skips the camera check.
        let stores = makeStores(remoteFlag: true)
        let availability = QRLoginAvailability(stores: stores,
                                               overrideStore: nil,
                                               rolloutBucket: makeBucket(value: 9),
                                               isCameraAvailable: { false })

        // When
        let enabled = await availability.isAvailableForDeepLink()

        // Then
        #expect(enabled == true)
    }

    @Test func isAvailableForDeepLink_when_flag_off_then_false() async {
        // Given
        let stores = makeStores(remoteFlag: false)
        let availability = QRLoginAvailability(stores: stores,
                                               overrideStore: nil,
                                               rolloutBucket: makeBucket(value: 1),
                                               isCameraAvailable: { true })

        // When
        let enabled = await availability.isAvailableForDeepLink()

        // Then
        #expect(enabled == false)
    }
}

// MARK: - Helpers

private extension QRLoginAvailabilityTests {

    func makeStores(remoteFlag: Bool) -> MockStoresManager {
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            if case let .isRemoteFeatureFlagEnabled(_, _, _, completion) = action {
                completion(remoteFlag)
            }
        }
        return stores
    }

    func makeBucket(value: Int) -> QRLoginRolloutBucket {
        QRLoginRolloutBucket(userDefaults: UserDefaults(suiteName: UUID().uuidString)!,
                             randomBucketProvider: { value })
    }
}

private final class StubOverrideStore: RemoteFeatureFlagOverrideStore {
    private let value: Bool?
    init(value: Bool?) { self.value = value }
    func overrideValue(for featureFlag: RemoteFeatureFlag) -> Bool? { value }
    func setOverrideValue(_ value: Bool?, for featureFlag: RemoteFeatureFlag) {}
}
