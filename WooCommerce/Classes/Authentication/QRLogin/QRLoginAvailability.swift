import AVFoundation
import Foundation
import Yosemite

/// Gates the QR-login entry points.
///
/// The `qrCodeLogin` remote feature flag is resolved through `FeatureFlagStore`.
/// The store returns a cached value when possible and otherwise loads remote
/// flags asynchronously, defaulting to `false` on failure.
///
/// Both gates are `@MainActor` because the Flux dispatcher must be called on
/// the main thread. (The requirements are isolated individually rather than
/// the whole protocol, so the conforming type's initializer stays non-isolated
/// and usable as a default argument.)
protocol QRLoginAvailabilityProvider {
    /// Prologue gate: remote flag on and a camera present on the device.
    @MainActor func isAvailableForPrologue() async -> Bool

    /// Deep-link gate: remote flag on. The camera check is bypassed —
    /// the merchant opted in by opening a `qr-login` URL.
    @MainActor func isAvailableForDeepLink() async -> Bool
}

struct QRLoginAvailability: QRLoginAvailabilityProvider {

    private let stores: StoresManager
    private let overrideStore: RemoteFeatureFlagOverrideStore?
    private let isCameraAvailable: () -> Bool

    init(stores: StoresManager = ServiceLocator.stores,
         overrideStore: RemoteFeatureFlagOverrideStore? = ServiceLocator.remoteFeatureFlagOverrideStore,
         isCameraAvailable: @escaping () -> Bool = QRLoginAvailability.defaultCameraAvailability) {
        self.stores = stores
        self.overrideStore = overrideStore
        self.isCameraAvailable = isCameraAvailable
    }

    @MainActor
    func isAvailableForPrologue() async -> Bool {
        // A debug override decides everything, bypassing the flag.
        if let override = debugOverride {
            return override
        }
        guard isCameraAvailable() else {
            return false
        }
        return await isRemoteFlagEnabled()
    }

    @MainActor
    func isAvailableForDeepLink() async -> Bool {
        if let override = debugOverride {
            return override
        }
        return await isRemoteFlagEnabled()
    }
}

private extension QRLoginAvailability {

    /// The debug override from the logged-out feature-flag panel, or `nil` when
    /// no override is set.
    var debugOverride: Bool? {
        overrideStore?.overrideValue(for: .qrCodeLogin)
    }

    /// Reads the `qrCodeLogin` remote flag from the feature-flag store.
    @MainActor
    func isRemoteFlagEnabled() async -> Bool {
        await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            let action = FeatureFlagAction.isRemoteFeatureFlagEnabled(.qrCodeLogin, defaultValue: false) { value in
                continuation.resume(returning: value)
            }
            stores.dispatch(action)
        }
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
