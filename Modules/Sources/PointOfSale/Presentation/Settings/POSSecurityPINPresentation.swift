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
            case .approval: .managerApproval
            case .editor: .fullScreen(title: "")
            case .guidedAccessGuide: .fullScreen(title: POSGuidedAccessGuideView.Localization.title)
            }
        }

        static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    }

    private enum State {
        case idle
        case presented(Destination)
        case dismissingApproval(UUID, POSPINSetupFlow?)
        case awaitingApprovalResult
    }

    private var state = State.idle

    var destination: Destination? {
        guard case .presented(let destination) = state else { return nil }
        return destination
    }

    var isTransitioning: Bool {
        switch state {
        case .dismissingApproval, .awaitingApprovalResult: true
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

    func finishApproval(editor: POSPINSetupFlow?) {
        guard let editor else {
            switch state {
            case .presented(.approval), .dismissingApproval, .awaitingApprovalResult: state = .idle
            case .idle, .presented(.editor), .presented(.guidedAccessGuide): break
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
        case .idle, .presented(.editor), .presented(.guidedAccessGuide): break
        }
    }

    func dismissalCompleted(for destination: Destination) {
        guard case .approval(let request) = destination,
              case .dismissingApproval(let id, let editor) = state,
              id == request.id else { return }
        if let editor {
            state = .presented(.editor(editor))
        } else {
            state = .awaitingApprovalResult
        }
    }

    func cancel() {
        state = .idle
    }
}
