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
    }

    deinit {
        observationTask?.cancel()
    }

    private func startObserving() {
        observationTask?.cancel()
        observationTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let newValue = withObservationTracking {
                    Self.shouldShowLockScreen(self.provider)
                } onChange: { }

                if newValue != self.isShowingLockScreen {
                    self.isShowingLockScreen = newValue
                }

                // Yield to let onChange fire before re-entering the loop
                try? await Task.sleep(for: .milliseconds(50))
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
