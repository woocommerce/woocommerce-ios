import SwiftUI
import Observation
import Combine

/// Bridges a `POSPermissionProviding` reference to SwiftUI's `ObservableObject`
/// world, and owns the PIN validation entry point shown by `POSLockScreenOverlay`.
@MainActor
final class POSLockScreenModel: ObservableObject {
    @Published private(set) var isShowingLockScreen: Bool = false

    private let provider: POSPermissionProviding
    private var observationTask: Task<Void, Never>?

    init(provider: POSPermissionProviding) {
        self.provider = provider
        self.isShowingLockScreen = Self.shouldShowLockScreen(provider)
        startObserving()
        refreshStaffOnEntry()
    }

    deinit {
        observationTask?.cancel()
    }

    /// Re-fetch the staff list whenever POS is entered, per the M1 plan:
    /// "the staff list is synced upon entering POS." Ensures local hashes reflect any
    /// web-admin changes made since the last sync.
    private func refreshStaffOnEntry() {
        let currentProvider = provider
        Task { @MainActor in
            await currentProvider.refreshPINStatus()
        }
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

    /// Authenticates a PIN by delegating to the concrete provider. Throws on
    /// invalid PIN / rate limit per `POSAuthError`.
    func authenticatePIN(_ pin: String) async throws {
        guard let permissionProvider = provider as? POSPermissionProvider else {
            // Test doubles / EmptyPOSPermissionProvider don't authenticate.
            return
        }
        _ = try await permissionProvider.authenticatePIN(pin)
        updateLockState()
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
        return hasNoOperator && (provider.isLocked || provider.hasAnyPINs)
    }
}
