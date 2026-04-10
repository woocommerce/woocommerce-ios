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
    private var observationTask: Task<Void, Never>?

    init(provider: POSPermissionProviding) {
        self.provider = provider
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
        if let local = provider as? LocalPOSPermissionProvider {
            let success = local.authenticatePIN(pin) != nil
            updateLockState()
            return success
        } else if let remote = provider as? RemotePOSPermissionProvider {
            do {
                _ = try await remote.authenticateRemotePIN(pin, registerID: "default")
                updateLockState()
                return true
            } catch {
                return false
            }
        }
        return false
    }

    private func updateLockState() {
        isShowingLockScreen = provider.isLocked && provider.currentOperator == nil
    }
}

/// Overlay that shows the POS lock screen when the permission provider is locked.
struct POSLockScreenOverlay: View {
    @StateObject private var model: POSLockScreenModel
    @State private var pinState: POSPINEntryState = .idle

    init(permissionProvider: POSPermissionProviding) {
        _model = StateObject(wrappedValue: POSLockScreenModel(provider: permissionProvider))
    }

    var body: some View {
        if model.isShowingLockScreen {
            POSLockScreenView(
                pinState: $pinState,
                onPINEntered: { pin in
                    handlePINEntered(pin)
                }
            )
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: model.isShowingLockScreen)
        }
    }

    private func handlePINEntered(_ pin: String) {
        Task { @MainActor in
            let success = await model.authenticatePIN(pin)
            if !success {
                pinState = .error(message: Localization.invalidPIN)
            } else {
                pinState = .idle
            }
        }
    }

    private enum Localization {
        static let invalidPIN = NSLocalizedString(
            "pos.lockScreen.invalidPIN",
            value: "Invalid PIN",
            comment: "Error shown when an incorrect PIN is entered on the POS lock screen"
        )
    }
}
