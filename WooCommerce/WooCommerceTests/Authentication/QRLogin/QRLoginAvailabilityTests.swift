import Foundation
import Testing
import Yosemite
import protocol Networking.RemoteFeatureFlagOverrideStore
@testable import WooCommerce

@MainActor
struct QRLoginAvailabilityTests {

    // MARK: - Prologue gating

    @Test func isAvailableForPrologue_when_flag_on_and_bucket_enabled_and_camera_available_then_true() async {
        // Given
        let availability = QRLoginAvailability(stores: makeStores(remoteFlag: true),
                                               overrideStore: nil,
                                               rolloutBucket: makeBucket(value: 1),
                                               isCameraAvailable: { true })

        // When / Then
        #expect(await availability.isAvailableForPrologue() == true)
    }

    @Test func isAvailableForPrologue_when_flag_off_then_false() async {
        // Given
        let availability = QRLoginAvailability(stores: makeStores(remoteFlag: false),
                                               overrideStore: nil,
                                               rolloutBucket: makeBucket(value: 1),
                                               isCameraAvailable: { true })

        // When / Then
        #expect(await availability.isAvailableForPrologue() == false)
    }

    @Test func isAvailableForPrologue_when_bucket_disabled_then_false() async {
        // Given
        let availability = QRLoginAvailability(stores: makeStores(remoteFlag: true),
                                               overrideStore: nil,
                                               rolloutBucket: makeBucket(value: 5),
                                               isCameraAvailable: { true })

        // When / Then
        #expect(await availability.isAvailableForPrologue() == false)
    }

    @Test func isAvailableForPrologue_when_no_camera_then_false() async {
        // Given
        let availability = QRLoginAvailability(stores: makeStores(remoteFlag: true),
                                               overrideStore: nil,
                                               rolloutBucket: makeBucket(value: 1),
                                               isCameraAvailable: { false })

        // When / Then
        #expect(await availability.isAvailableForPrologue() == false)
    }

    @Test func isAvailableForPrologue_when_debug_override_true_then_bypasses_flag_and_bucket() async {
        // Given — override true, but the flag is off and the bucket is disabled.
        let availability = QRLoginAvailability(stores: makeStores(remoteFlag: false),
                                               overrideStore: StubOverrideStore(value: true),
                                               rolloutBucket: makeBucket(value: 9),
                                               isCameraAvailable: { true })

        // When / Then
        #expect(await availability.isAvailableForPrologue() == true)
    }

    @Test func isAvailableForPrologue_when_debug_override_false_then_disabled_regardless_of_flag() async {
        // Given
        let availability = QRLoginAvailability(stores: makeStores(remoteFlag: true),
                                               overrideStore: StubOverrideStore(value: false),
                                               rolloutBucket: makeBucket(value: 1),
                                               isCameraAvailable: { true })

        // When / Then
        #expect(await availability.isAvailableForPrologue() == false)
    }

    @Test func isAvailableForPrologue_when_remote_flag_completes_asynchronously_then_waits_for_result() async {
        // Given
        let availability = QRLoginAvailability(stores: makeStores(remoteFlag: true, completionTiming: .deferred),
                                               overrideStore: nil,
                                               rolloutBucket: makeBucket(value: 1),
                                               isCameraAvailable: { true })

        // When / Then
        #expect(await availability.isAvailableForPrologue() == true)
    }

    // MARK: - Deep-link gating

    @Test func isAvailableForDeepLink_when_flag_on_then_true_even_if_bucket_disabled_and_camera_unavailable() async {
        // Given — deep-link bypasses the bucket and skips the camera check.
        let availability = QRLoginAvailability(stores: makeStores(remoteFlag: true),
                                               overrideStore: nil,
                                               rolloutBucket: makeBucket(value: 9),
                                               isCameraAvailable: { false })

        // When / Then
        #expect(await availability.isAvailableForDeepLink() == true)
    }

    @Test func isAvailableForDeepLink_when_flag_off_then_false() async {
        // Given
        let availability = QRLoginAvailability(stores: makeStores(remoteFlag: false),
                                               overrideStore: nil,
                                               rolloutBucket: makeBucket(value: 1),
                                               isCameraAvailable: { true })

        // When / Then
        #expect(await availability.isAvailableForDeepLink() == false)
    }

    @Test func isAvailableForDeepLink_when_debug_override_true_then_true() async {
        // Given
        let availability = QRLoginAvailability(stores: makeStores(remoteFlag: false),
                                               overrideStore: StubOverrideStore(value: true),
                                               rolloutBucket: makeBucket(value: 9),
                                               isCameraAvailable: { false })

        // When / Then
        #expect(await availability.isAvailableForDeepLink() == true)
    }
}

// MARK: - Helpers

private extension QRLoginAvailabilityTests {

    enum CompletionTiming {
        case immediate
        case deferred
    }

    /// A `MockStoresManager` that answers `FeatureFlagAction.isRemoteFeatureFlagEnabled`.
    func makeStores(remoteFlag: Bool, completionTiming: CompletionTiming = .immediate) -> MockStoresManager {
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            if case let .isRemoteFeatureFlagEnabled(_, _, _, completion) = action {
                switch completionTiming {
                case .immediate:
                    completion(remoteFlag)
                case .deferred:
                    Task { @MainActor in
                        await Task.yield()
                        completion(remoteFlag)
                    }
                }
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
    func removeAllOverrides() {}
}
