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
        self.isShowingLockScreen = provider.isLocked && provider.currentOperator == nil
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
                    self.provider.isLocked && self.provider.currentOperator == nil
                } onChange: { }

                if newValue != self.isShowingLockScreen {
                    self.isShowingLockScreen = newValue
                }

                // Yield to let onChange fire before re-entering the loop
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    func authenticatePIN(_ pin: String) async -> Bool {
        let success = await authenticator.authenticate(pin: pin)
        if success {
            updateLockState()
        }
        return success
    }

    private func updateLockState() {
        isShowingLockScreen = provider.isLocked && provider.currentOperator == nil
    }
}
