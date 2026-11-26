import Foundation
import Observation

@MainActor
@Observable
final class POSSecurityPINPresentation {
    enum Destination: Identifiable, Equatable {
        case approval(POSManagerOverrideRequest)
        case editor(POSPINSetupFlow)
        case guidedAccessGuide

        var id: AnyHashable {
            switch self {
            case .approval(let request): AnyHashable(request.id)
            case .editor(let flow): AnyHashable(ObjectIdentifier(flow))
            case .guidedAccessGuide: AnyHashable("guidedAccessGuide")
            }
        }

        var compactStyle: POSModalCompactStyle {
            switch self {
            case .approval, .editor: .pinEntry
            case .guidedAccessGuide: .fullScreen(title: POSGuidedAccessGuideView.Localization.title)
            }
        }

        static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    }

    private enum State {
        case idle
        case presented(Destination)
        case dismissingApproval(UUID, POSPINSetupFlow?)
        case dismissingEditorForGuide(ObjectIdentifier)
        case awaitingApprovalResult
    }

    private var state = State.idle

    var destination: Destination? {
        guard case .presented(let destination) = state else { return nil }
        return destination
    }

    var isTransitioning: Bool {
        switch state {
        case .dismissingApproval, .dismissingEditorForGuide, .awaitingApprovalResult: true
        case .idle, .presented: false
        }
    }

    func present(_ destination: Destination) {
        state = .presented(destination)
    }

    func approvalEnded() {
        guard case .presented(.approval(let request)) = state else { return }
        state = .dismissingApproval(request.id, nil)
    }

    func dismissEditorForGuide(_ editor: POSPINSetupFlow) -> Bool {
        guard case .presented(.editor(let current)) = state, current === editor else {
            return false
        }
        state = .dismissingEditorForGuide(ObjectIdentifier(editor))
        return true
    }

    func finishApproval(editor: POSPINSetupFlow?) {
        guard let editor else {
            switch state {
            case .presented(.approval), .dismissingApproval, .awaitingApprovalResult: state = .idle
            case .idle, .presented(.editor), .presented(.guidedAccessGuide), .dismissingEditorForGuide: break
            }
            return
        }
        switch state {
        case .presented(.approval(let request)):
            state = .dismissingApproval(request.id, editor)
        case .dismissingApproval(let id, _):
            state = .dismissingApproval(id, editor)
        case .awaitingApprovalResult:
            state = .presented(.editor(editor))
        case .idle, .presented(.editor), .presented(.guidedAccessGuide), .dismissingEditorForGuide: break
        }
    }

    func dismissalCompleted(for destination: Destination) {
        switch (destination, state) {
        case (.approval(let request), .dismissingApproval(let id, let editor)) where id == request.id:
            if let editor {
                state = .presented(.editor(editor))
            } else {
                state = .awaitingApprovalResult
            }
        case (.editor(let editor), .dismissingEditorForGuide(let id)) where ObjectIdentifier(editor) == id:
            state = .presented(.guidedAccessGuide)
        default:
            break
        }
    }

    func cancel() {
        state = .idle
    }
}
