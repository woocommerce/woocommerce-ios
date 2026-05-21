import AVFoundation
import Foundation
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
/// `authenticationUI()` is synchronous and can't await the remote-flag
/// round-trip, so `refreshAvailability()` resolves the async gates ahead of
/// time and caches the result; the `…Sync` accessors then read that cache.
/// A debug override is always honoured synchronously and bypasses both the
/// remote flag and the rollout bucket.
protocol QRLoginAvailabilityProvider {
    func isAvailableForPrologue() async -> Bool
    func isAvailableForDeepLink() async -> Bool

    /// Resolves the async prologue / deep-link gates and caches the results so
    /// the synchronous accessors can return an up-to-date value. Call this when
    /// the login UI is built, before the merchant can reach a QR entry point.
    @MainActor func refreshAvailability() async

    /// Synchronous prologue gate. Returns the debug override when set; otherwise
    /// the value cached by the most recent `refreshAvailability()`, or `false`
    /// when the cache is cold (spec §2: a not-yet-loaded remote value is off).
    @MainActor func isAvailableForPrologueSync() -> Bool

    /// Synchronous deep-link gate. Returns the debug override when set; otherwise
    /// the cached value, or `nil` when the cache is cold so the caller can fall
    /// back to the standard login handlers (spec §2.2).
    @MainActor func isAvailableForDeepLinkSync() -> Bool?
}

final class QRLoginAvailability: QRLoginAvailabilityProvider {

    private let stores: StoresManager
    private let overrideStore: RemoteFeatureFlagOverrideStore?
    private let rolloutBucket: QRLoginRolloutBucket
    private let isCameraAvailable: () -> Bool

    /// Results of the async gates, cached by `refreshAvailability()`.
    /// `nil` means "not resolved yet".
    private var cachedPrologueAvailability: Bool?
    private var cachedDeepLinkAvailability: Bool?

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

    @MainActor
    func refreshAvailability() async {
        // Resolved sequentially: the second call hits the feature-flag store's
        // warmed cache, so this is one network round-trip, not two.
        let prologue = await isAvailableForPrologue()
        let deepLink = await isAvailableForDeepLink()
        cachedPrologueAvailability = prologue
        cachedDeepLinkAvailability = deepLink
    }

    @MainActor
    func isAvailableForPrologueSync() -> Bool {
        guard isCameraAvailable() else { return false }
        if let override = overrideStore?.overrideValue(for: .qrCodeLogin) {
            return override
        }
        return cachedPrologueAvailability ?? false
    }

    @MainActor
    func isAvailableForDeepLinkSync() -> Bool? {
        if let override = overrideStore?.overrideValue(for: .qrCodeLogin) {
            return override
        }
        return cachedDeepLinkAvailability
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
        #if targetEnvironment(simulator)
        // Simulators never expose a video capture device. Report a camera as
        // available so the QR-login prologue is reachable for development and
        // UI testing on the simulator. This branch is compiled out of every
        // device build (including App Store builds), so real hardware is
        // still gated on an actual camera.
        return true
        #else
        return AVCaptureDevice.default(for: .video) != nil
        #endif
    }
}
