import Foundation
import Observation

@Observable
@MainActor
final class POSExitFlow {
    struct Confirmation: Identifiable, Equatable {
        let id = UUID()
        let sessionID: ObjectIdentifier
        let scope: POSPINSessionTokens.Token

        @MainActor
        func belongs(to session: POSAccessSession) -> Bool {
            sessionID == ObjectIdentifier(session) && scope == session.accessScope && !session.isLocked
        }
    }

    private enum Stage {
        case idle
        case confirming(Confirmation)
        case dismissing(Confirmation)
        case authorizing(Confirmation)
        case exited
    }

    let approvalHandler = POSManagerOverrideHandler()
    private var stage: Stage = .idle

    var confirmation: Confirmation? {
        guard case .confirming(let request) = stage else { return nil }
        return request
    }

    func request(session: POSAccessSession) {
        guard !session.isLocked else { return }
        switch stage {
        case .idle: break
        case .authorizing where approvalHandler.request == nil: break
        case .confirming, .dismissing, .authorizing, .exited: return
        }
        approvalHandler.configure(session: session)
        stage = .confirming(Confirmation(sessionID: ObjectIdentifier(session), scope: session.accessScope))
    }

    func confirm(_ request: Confirmation) {
        guard confirmation == request else { return }
        stage = .dismissing(request)
    }

    func cancelConfirmation() {
        guard confirmation != nil else { return }
        stage = .idle
    }

    func confirmationDismissed(_ request: Confirmation,
                               session: POSAccessSession,
                               reason: String,
                               onExit: @escaping () -> Void) {
        guard case .dismissing(let pending) = stage, pending == request else { return }
        guard request.belongs(to: session) else {
            cancel()
            return
        }
        // Wait for the shared dialog's removal before presenting approval in the same modal host.
        stage = .authorizing(request)
        approvalHandler.gate(.exitPOS, reason: reason) { _ in
            guard case .authorizing(let pending) = self.stage,
                  pending == request, request.belongs(to: session) else { return }
            self.stage = .exited
            onExit()
        }
    }

    func cancel() {
        stage = .idle
        approvalHandler.cancel()
    }
}
