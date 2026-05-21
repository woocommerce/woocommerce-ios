import AVFoundation
import Foundation
import Yosemite

/// Synchronously gates the QR-login entry points.
///
/// The `qrCodeLogin` remote feature flag is read straight from the feature-flag
/// store: the app fetches remote flags at launch, and dispatching
/// `FeatureFlagAction.isRemoteFeatureFlagEnabled` runs its completion
/// synchronously on a cache hit (and for a debug override). A cold cache reads
/// as `false`, per spec §2 ("a not-yet-loaded remote value is treated as off").
///
/// Both gates are `@MainActor` because the Flux dispatcher must be called on
/// the main thread. (The requirements are isolated individually rather than
/// the whole protocol, so the conforming type's initializer stays non-isolated
/// and usable as a default argument.)
protocol QRLoginAvailabilityProvider {
    /// Prologue gate (spec §2.1): remote flag on, install in the enabled
    /// rollout bucket, and a camera present on the device.
    @MainActor func isAvailableForPrologue() -> Bool

    /// Deep-link gate (spec §2.2): remote flag on. The rollout bucket and the
    /// camera are bypassed — the merchant opted in by opening a `qr-login` URL.
    @MainActor func isAvailableForDeepLink() -> Bool
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

    @MainActor
    func isAvailableForPrologue() -> Bool {
        // A debug override decides everything, bypassing the flag and bucket.
        if let override = debugOverride {
            return override
        }
        return isCameraAvailable() && isRemoteFlagEnabled() && rolloutBucket.isEnabled
    }

    @MainActor
    func isAvailableForDeepLink() -> Bool {
        debugOverride ?? isRemoteFlagEnabled()
    }
}

private extension QRLoginAvailability {

    /// The debug override from the logged-out feature-flag panel, or `nil` when
    /// no override is set.
    var debugOverride: Bool? {
        overrideStore?.overrideValue(for: .qrCodeLogin)
    }

    /// Reads the `qrCodeLogin` remote flag from the feature-flag store. The
    /// completion runs synchronously on a cache hit; a cold cache leaves the
    /// result `false`.
    @MainActor
    func isRemoteFlagEnabled() -> Bool {
        var isEnabled = false
        let action = FeatureFlagAction.isRemoteFeatureFlagEnabled(.qrCodeLogin, defaultValue: false) { value in
            isEnabled = value
        }
        stores.dispatch(action)
        return isEnabled
    }

    static func defaultCameraAvailability() -> Bool {
        #if targetEnvironment(simulator)
        // Simulators never expose a video capture device. Report a camera as
        // available so the QR-login prologue is reachable for development and
        // UI testing. Compiled out of every device build.
        return true
        #else
        return AVCaptureDevice.default(for: .video) != nil
        #endif
    }
}
