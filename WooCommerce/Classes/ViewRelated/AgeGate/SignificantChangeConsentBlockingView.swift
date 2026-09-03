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
            Button(Localization.checkAgainButton, action: onCheckAgain)
                .buttonStyle(PrimaryButtonStyle())
            if context == .approvalDenied {
                Button(Localization.askAgainButton, action: onAskAgain)
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(Layout.padding)
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
    }

    enum Localization {
        static let pendingTitle = NSLocalizedString(
            "significantChangeConsent.blocking.pending.title",
            value: "Approval Needed",
            comment: "Title of the blocking screen shown while a parent/guardian approval " +
            "for a significant app change is pending."
        )
        static let pendingMessage = NSLocalizedString(
            "significantChangeConsent.blocking.pending.message",
            value: "A parent or guardian needs to approve recent changes to this app before you can continue. " +
            "Once they respond to the approval request, tap Check Again.",
            comment: "Message of the blocking screen shown while a parent/guardian approval " +
            "for a significant app change is pending."
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
