import SwiftUI

public enum AgeGateBlockReason {
    case tooYoung
    case consentRevoked

    var title: String {
        switch self {
        case .tooYoung: return "Access Not Allowed"
        case .consentRevoked: return "Access Revoked"
        }
    }

    var message: String {
        switch self {
        case .tooYoung:
            return "Based on your account settings, you're not eligible to use this app."
        case .consentRevoked:
            return "Permission to use this app has been revoked by your Apple family settings."
        }
    }
}

public struct AgeGateBlockedView: View {
    let reason: AgeGateBlockReason
    let onPrimaryAction: () -> Void

    public init(reason: AgeGateBlockReason, onPrimaryAction: @escaping () -> Void) {
        self.reason = reason
        self.onPrimaryAction = onPrimaryAction
    }

    public var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(reason.title)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text(reason.message)
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
            Button("Return to Login", action: onPrimaryAction)
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

public final class AgeGateBlockedHostingController: UIHostingController<AgeGateBlockedView> {
    public init(reason: AgeGateBlockReason, onPrimaryAction: @escaping () -> Void) {
        super.init(rootView: AgeGateBlockedView(reason: reason, onPrimaryAction: onPrimaryAction))
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    public required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
