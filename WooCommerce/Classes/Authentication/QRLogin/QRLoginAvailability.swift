import AVFoundation
import Foundation
import protocol Networking.RemoteFeatureFlagOverrideStore
import Yosemite

/// Computes whether the QR-login flow is available right now.
///
/// Two entry points have different gating per spec §2.1 / §2.2:
///   - **Prologue**: remote flag (or debug override) on, bucket in the enabled
///     range, and a camera is present on the device.
///   - **Deep link**: only the remote flag (or debug override) needs to be on.
///     The bucket is bypassed (the user explicitly opened a `qr-login` URL) and
///     no camera is needed (the token is already in the URL).
///
/// A debug override (set via the logged-out feature-flag panel) bypasses both
/// the remote flag and the rollout bucket entirely.
protocol QRLoginAvailabilityProvider {
    func isAvailableForPrologue() async -> Bool
    func isAvailableForDeepLink() async -> Bool
    /// Synchronous check used at prologue construction time. Honours the
    /// debug override and the rollout bucket but skips the remote-flag
    /// network round-trip — treats an unknown remote flag as off, matching
    /// spec §2 ("null / not-yet-loaded remote value is treated as off").
    func isAvailableForPrologueSync() -> Bool
}

struct QRLoginAvailability: QRLoginAvailabilityProvider {

    private let stores: StoresManager
    private let overrideStore: RemoteFeatureFlagOverrideStore?
    private let rolloutBucket: QRLoginRolloutBucket
    private let isCameraAvailable: () -> Bool

    init(stores: StoresManager = ServiceLocator.stores,
         overrideStore: RemoteFeatureFlagOverrideStore? = ServiceLocator.remoteFeatureFlagOverrideStore,
         rolloutBucket: QRLoginRolloutBucket = QRLoginRolloutBucket(),
         isCameraAvailable: @escaping () -> Bool = QRLoginAvailability.defaultCameraAvailability) {
        self.stores = stores
        self.overrideStore = overrideStore
        self.rolloutBucket = rolloutBucket
        self.isCameraAvailable = isCameraAvailable
    }

    func isAvailableForPrologue() async -> Bool {
        guard isCameraAvailable() else { return false }
        return await isEnabledRespectingOverride(includeBucketCheck: true)
    }

    func isAvailableForDeepLink() async -> Bool {
        await isEnabledRespectingOverride(includeBucketCheck: false)
    }

    func isAvailableForPrologueSync() -> Bool {
        guard isCameraAvailable() else { return false }
        if let override = overrideStore?.overrideValue(for: .qrCodeLogin) {
            return override
        }
        // No override: without an async dispatch we can't read the cached
        // flag value, so we report unavailable. The async `isAvailableForPrologue`
        // is the production path; the sync version is for the prologue
        // construction site where the debug-override is enough to drive
        // testing on simulator.
        return false
    }
}

private extension QRLoginAvailability {

    /// `true` when either:
    ///   - a debug override is set and is `true`, OR
    ///   - no override is set, the remote flag is `true`, AND (if
    ///     `includeBucketCheck`) the install is in the enabled bucket.
    ///
    /// When `includeBucketCheck` is `false` the bucket isn't consulted — used
    /// for deep-link entry where the user already opted into the flow.
    func isEnabledRespectingOverride(includeBucketCheck: Bool) async -> Bool {
        if let override = overrideStore?.overrideValue(for: .qrCodeLogin) {
            return override
        }
        let flagEnabled = await isRemoteFlagEnabled()
        guard flagEnabled else { return false }
        if includeBucketCheck, rolloutBucket.isEnabled == false {
            return false
        }
        return true
    }

    func isRemoteFlagEnabled() async -> Bool {
        await withCheckedContinuation { continuation in
            // Default `false` per spec §2 ("a `null` / not-yet-loaded remote
            // value is treated as off").
            let action = FeatureFlagAction.isRemoteFeatureFlagEnabled(.qrCodeLogin, defaultValue: false) { isEnabled in
                continuation.resume(returning: isEnabled)
            }
            stores.dispatch(action)
        }
    }

    static func defaultCameraAvailability() -> Bool {
        AVCaptureDevice.default(for: .video) != nil
    }
}
