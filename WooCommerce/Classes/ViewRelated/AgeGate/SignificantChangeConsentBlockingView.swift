import SwiftUI

/// Why access is currently restricted by the significant-change consent flow.
enum SignificantChangeBlockingContext {
    /// The consent question was sent and the parent/guardian hasn't answered yet.
    case pendingApproval
    /// The parent/guardian declined the consent question.
    case approvalDenied
}

/// Full-screen, non-dismissable blocking screen shown while a significant-change consent is
/// pending or after it was denied. Recoverable by design: no logout, just re-check / re-ask.
final class SignificantChangeConsentBlockingHostingController: UIHostingController<SignificantChangeConsentBlockingView> {
    init(context: SignificantChangeBlockingContext,
         onCheckAgain: @escaping () -> Void,
         onAskAgain: @escaping () -> Void) {
        super.init(rootView: SignificantChangeConsentBlockingView(
            context: context,
            onCheckAgain: onCheckAgain,
            onAskAgain: onAskAgain
        ))
        modalPresentationStyle = .fullScreen
        isModalInPresentation = true
    }

    func update(context: SignificantChangeBlockingContext) {
        rootView = SignificantChangeConsentBlockingView(
            context: context,
            onCheckAgain: rootView.onCheckAgain,
            onAskAgain: rootView.onAskAgain
        )
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct SignificantChangeConsentBlockingView: View {
    let context: SignificantChangeBlockingContext
    let onCheckAgain: () -> Void
    let onAskAgain: () -> Void

    /// Brief in-button progress after a tap. The underlying re-check can resolve instantly,
    /// which otherwise looks like the tap wasn't registered at all.
    @State private var isWorking = false

    var body: some View {
        VStack(spacing: Layout.spacing) {
            Spacer()
            Image(systemName: context == .pendingApproval ? "person.badge.clock" : "hand.raised")
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
            switch context {
            case .pendingApproval:
                Button(Localization.checkAgainButton) {
                    perform(onCheckAgain)
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isWorking))
            case .approvalDenied:
                // A stored denial can only be lifted by sending a new request —
                // there is no state to "re-check" until a new answer arrives.
                Button(Localization.askAgainButton) {
                    perform(onAskAgain)
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isWorking))
            }
        }
        .padding(Layout.padding)
    }

    private func perform(_ action: @escaping () -> Void) {
        guard isWorking == false else { return }
        isWorking = true
        action()
        DispatchQueue.main.asyncAfter(deadline: .now() + Layout.minimumWorkingIndicationDuration) {
            isWorking = false
        }
    }
}

private extension SignificantChangeConsentBlockingView {
    var title: String {
        switch context {
        case .pendingApproval:
            return Localization.pendingTitle
        case .approvalDenied:
            return Localization.deniedTitle
        }
    }

    var message: String {
        switch context {
        case .pendingApproval:
            return Localization.pendingMessage
        case .approvalDenied:
            return Localization.deniedMessage
        }
    }

    enum Layout {
        static let spacing: CGFloat = 16
        static let padding: CGFloat = 24
        static let iconSize: CGFloat = 56
        static let minimumWorkingIndicationDuration: TimeInterval = 1
    }

    enum Localization {
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
        static let checkAgainButton = NSLocalizedString(
            "significantChangeConsent.blocking.checkAgain.button",
            value: "Check Again",
            comment: "Button on the significant-change blocking screen that re-checks the approval status."
        )
        static let askAgainButton = NSLocalizedString(
            "significantChangeConsent.blocking.askAgain.button",
            value: "Ask Again",
            comment: "Button on the significant-change blocking screen that sends the approval request again."
        )
    }
}

#Preview("Pending") {
    SignificantChangeConsentBlockingView(context: .pendingApproval, onCheckAgain: {}, onAskAgain: {})
}

#Preview("Denied") {
    SignificantChangeConsentBlockingView(context: .approvalDenied, onCheckAgain: {}, onAskAgain: {})
}
