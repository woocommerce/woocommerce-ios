import SwiftUI
import Observation
import Combine

/// Bridges a POSPermissionProviding protocol reference to SwiftUI observation.
/// Uses withObservationTracking to detect changes on the @Observable providers
/// and republish them as @Published for SwiftUI.
@MainActor
final class POSLockScreenModel: ObservableObject {
    @Published private(set) var isShowingLockScreen: Bool = false

    private let provider: POSPermissionProviding
    private let authenticator: POSPINAuthenticating
    private var observationTask: Task<Void, Never>?

    init(provider: POSPermissionProviding,
         authenticator: POSPINAuthenticating) {
        self.provider = provider
        self.authenticator = authenticator
        self.isShowingLockScreen = Self.shouldShowLockScreen(provider)
        startObserving()
        refreshRemoteStaffStatusIfNeeded()
    }

    /// For remote providers, fetch the current staff list so `hasAnyPINs` reflects
    /// backend state. This covers the "admin deleted all users / removed all PINs
    /// while POS was locked" case — the refresh will clear `hasAnyPINs` (and the
    /// persisted lock flag), and the observed `isShowingLockScreen` will drop.
    private func refreshRemoteStaffStatusIfNeeded() {
        guard let remote = provider as? RemotePOSPermissionProvider else { return }
        Task { @MainActor in
            await remote.refreshStaffStatus()
        }
    }

    deinit {
        observationTask?.cancel()
    }

    private func startObserving() {
        observationTask?.cancel()
        observationTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }

                // Wait for the next property change using a continuation.
                // withObservationTracking registers observation, and onChange
                // fires once when any observed property changes.
                await withCheckedContinuation { continuation in
                    let newValue = withObservationTracking {
                        Self.shouldShowLockScreen(self.provider)
                    } onChange: {
                        continuation.resume()
                    }

                    if newValue != self.isShowingLockScreen {
                        self.isShowingLockScreen = newValue
                    }
                }

                // Re-read after onChange (which fires with willSet semantics)
                let updatedValue = Self.shouldShowLockScreen(self.provider)
                if updatedValue != self.isShowingLockScreen {
                    self.isShowingLockScreen = updatedValue
                }
            }
        }
    }

    /// Authenticates a PIN. Returns true on success, false on wrong PIN.
    /// Throws `POSAuthError.rateLimited` when too many failed attempts.
    func authenticatePIN(_ pin: String) async throws -> Bool {
        let success = try await authenticator.authenticate(pin: pin)
        if success {
            updateLockState()
        }
        return success
    }

    private func updateLockState() {
        isShowingLockScreen = Self.shouldShowLockScreen(provider)
    }

    /// The lock screen should show when:
    /// 1. PINs are configured AND no operator is signed in (first open or after lock)
    /// 2. Provider is explicitly locked (persists across app kills via UserDefaults)
    ///
    /// When PINs are enabled, there is no "unlocked with no operator" state.
    /// Someone must authenticate via PIN before using POS.
    private static func shouldShowLockScreen(_ provider: POSPermissionProviding) -> Bool {
        let hasNoOperator = provider.currentOperator == nil
        // Show lock screen if explicitly locked, or if PINs exist but nobody signed in
        return hasNoOperator && (provider.isLocked || provider.hasAnyPINs)
    }
}
