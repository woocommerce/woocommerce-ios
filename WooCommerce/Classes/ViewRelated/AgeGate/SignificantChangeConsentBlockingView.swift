import SwiftUI

/// Why access is currently restricted by the significant-change consent flow.
enum SignificantChangeBlockingContext {
    /// Consent is required and the request hasn't been sent yet — the user sends it explicitly.
    case approvalNeeded
    /// The consent question was sent and the parent/guardian hasn't answered yet.
    case pendingApproval
    /// The parent/guardian declined the consent question.
    case approvalDenied
}

/// Full-screen, non-dismissable blocking screen for the significant-change consent flow.
/// Recoverable by design: no logout — the user requests approval, re-checks, or re-asks.
final class SignificantChangeConsentBlockingHostingController: UIHostingController<SignificantChangeConsentBlockingView> {
    init(context: SignificantChangeBlockingContext, onAction: @escaping () -> Void) {
        super.init(rootView: SignificantChangeConsentBlockingView(context: context, onAction: onAction))
        modalPresentationStyle = .fullScreen
        isModalInPresentation = true
    }

    func update(context: SignificantChangeBlockingContext, onAction: @escaping () -> Void) {
        rootView = SignificantChangeConsentBlockingView(context: context, onAction: onAction)
    }

    @available(*, unavailable)
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct SignificantChangeConsentBlockingView: View {
    let context: SignificantChangeBlockingContext
    let onAction: () -> Void

    /// Brief in-button progress after a tap. The underlying work can resolve instantly,
    /// which otherwise looks like the tap wasn't registered at all.
    @State private var isWorking = false

    var body: some View {
        VStack(spacing: Layout.spacing) {
            Spacer()
            Image(systemName: iconName)
                .font(.system(size: Layout.iconSize))
                .foregroundColor(.secondary)
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button(actionTitle) {
                guard isWorking == false else { return }
                isWorking = true
                onAction()
                DispatchQueue.main.asyncAfter(deadline: .now() + Layout.minimumWorkingIndicationDuration) {
                    isWorking = false
                }
            }
            .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isWorking))
        }
        .padding(Layout.padding)
    }
}

private extension SignificantChangeConsentBlockingView {
    var iconName: String {
        switch context {
        case .approvalNeeded:
            return "person.badge.shield.checkmark"
        case .pendingApproval:
            return "person.badge.clock"
        case .approvalDenied:
            return "hand.raised"
        }
    }

    var title: String {
        switch context {
        case .approvalNeeded:
            return Localization.neededTitle
        case .pendingApproval:
            return Localization.pendingTitle
        case .approvalDenied:
            return Localization.deniedTitle
        }
    }

    var message: String {
        switch context {
        case .approvalNeeded:
            return Localization.neededMessage
        case .pendingApproval:
            return Localization.pendingMessage
        case .approvalDenied:
            return Localization.deniedMessage
        }
    }

    var actionTitle: String {
        switch context {
        case .approvalNeeded:
            return Localization.requestApprovalButton
        case .pendingApproval:
            return Localization.checkAgainButton
        case .approvalDenied:
            return Localization.askAgainButton
        }
    }

    enum Layout {
        static let spacing: CGFloat = 16
        static let padding: CGFloat = 24
        static let iconSize: CGFloat = 56
        static let minimumWorkingIndicationDuration: TimeInterval = 1
    }

    enum Localization {
        static let neededTitle = NSLocalizedString(
            "significantChangeConsent.blocking.needed.title",
            value: "Approval Needed",
            comment: "Title of the blocking screen shown when a significant app change requires " +
            "a parent/guardian approval that hasn't been requested yet."
        )
        static let neededMessage = NSLocalizedString(
            "significantChangeConsent.blocking.needed.message",
            value: "Recent changes to this app need to be approved by your parent or guardian " +
            "before you can continue. Send them an approval request to proceed.",
            comment: "Message of the blocking screen shown when a significant app change requires " +
            "a parent/guardian approval that hasn't been requested yet."
        )
        static let requestApprovalButton = NSLocalizedString(
            "significantChangeConsent.blocking.requestApproval.button",
            value: "Request Approval",
            comment: "Button on the significant-change blocking screen that sends the approval " +
            "request to a parent/guardian."
        )
        static let pendingTitle = NSLocalizedString(
            "significantChangeConsent.blocking.pendingRequested.title",
            value: "Approval Requested",
            comment: "Title of the blocking screen shown after an approval request for a " +
            "significant app change was sent to a parent/guardian and is awaiting their response."
        )
        static let pendingMessage = NSLocalizedString(
            "significantChangeConsent.blocking.pendingRequested.message",
            value: "We've sent an approval request for recent changes to this app to your parent or guardian. " +
            "Once they respond, tap Check Again to continue.",
            comment: "Message of the blocking screen shown after an approval request for a " +
            "significant app change was sent to a parent/guardian and is awaiting their response."
        )
        static let checkAgainButton = NSLocalizedString(
            "significantChangeConsent.blocking.checkAgain.button",
            value: "Check Again",
            comment: "Button on the significant-change blocking screen that re-checks the approval status."
        )
        static let deniedTitle = NSLocalizedString(
            "significantChangeConsent.blocking.denied.title",
            value: "Approval Declined",
            comment: "Title of the blocking screen shown when a parent/guardian declined " +
            "the approval for a significant app change."
        )
        static let deniedMessage = NSLocalizedString(
            "significantChangeConsent.blocking.denied.message",
            value: "A parent or guardian declined the approval needed to continue using this app. " +
            "You can send the approval request again.",
            comment: "Message of the blocking screen shown when a parent/guardian declined " +
            "the approval for a significant app change."
        )
        static let askAgainButton = NSLocalizedString(
            "significantChangeConsent.blocking.askAgain.button",
            value: "Ask Again",
            comment: "Button on the significant-change blocking screen that sends the approval request again."
        )
    }
}

#Preview("Needed") {
    SignificantChangeConsentBlockingView(context: .approvalNeeded, onAction: {})
}

#Preview("Pending") {
    SignificantChangeConsentBlockingView(context: .pendingApproval, onAction: {})
}

#Preview("Denied") {
    SignificantChangeConsentBlockingView(context: .approvalDenied, onAction: {})
}
