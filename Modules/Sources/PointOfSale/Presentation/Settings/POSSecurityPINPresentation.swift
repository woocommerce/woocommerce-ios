import Foundation
import Observation

@MainActor
@Observable
final class POSSecurityPINPresentation {
    enum Destination: Identifiable, Equatable {
        case approval(POSManagerOverrideRequest)
        case editor(POSPINSetupFlow)

        var id: AnyHashable {
            switch self {
            case .approval(let request): AnyHashable(request.id)
            case .editor(let flow): AnyHashable(ObjectIdentifier(flow))
            }
        }

        func compactStyle(editorTitle: String) -> POSModalCompactStyle {
            switch self {
            case .approval: .managerApproval
            case .editor: .fullScreen(title: editorTitle)
            }
        }

        static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    }

    private enum State {
        case idle
        case presented(Destination)
        case dismissingApproval(UUID, POSPINSetupFlow)
    }

    private var state = State.idle

    var destination: Destination? {
        guard case .presented(let destination) = state else { return nil }
        return destination
    }

    func present(_ destination: Destination) {
        state = .presented(destination)
    }

    func finishApproval(editor: POSPINSetupFlow?) {
        guard case .presented(.approval(let request)) = state else { return }
        if let editor {
            state = .dismissingApproval(request.id, editor)
        } else {
            state = .idle
        }
    }

    func dismissalCompleted(for destination: Destination) {
        guard case .approval(let request) = destination,
              case .dismissingApproval(let id, let editor) = state,
              id == request.id else { return }
        state = .presented(.editor(editor))
    }

    func cancel() {
        state = .idle
    }
}
