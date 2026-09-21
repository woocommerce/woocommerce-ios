import SwiftUI

/// Number-matching overlay. Shown after `/scan` returns successfully.
///
/// Drives a one-second countdown clamped at zero — purely a UI hint;
/// termination is owned by the polling loop, not the timer.
struct QRLoginNumberMatchView: View {
    let realNumber: String
    let expiresAt: Date
    let subtitle: QRLoginNumberMatchSubtitle
    let onCancel: () -> Void

    @State private var now = Date()
    private let timer = Timer.publish(every: Constants.countdownTimerInterval, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: Constants.standardSpacing) {
            Spacer()

            Text(Localization.title)
                .font(.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: Constants.smallSpacing) {
                Text(subtitleLabel)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text(verbatim: subtitleValue)
                    .font(.headline)
                    .padding(.horizontal, Constants.mediumPadding)
                    .padding(.vertical, Constants.smallSpacing)
                    .background(
                        RoundedRectangle(cornerRadius: Constants.subtitleCornerRadius)
                            .fill(Color(uiColor: .systemGray6))
                    )
            }

            Text(Localization.tapHint)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text(verbatim: realNumber)
                .font(.system(size: Constants.numberFontSize, weight: .semibold, design: .monospaced))
                .padding(.horizontal, Constants.largePadding)
                .padding(.vertical, Constants.mediumPadding)
                .background(
                    RoundedRectangle(cornerRadius: Constants.numberCornerRadius)
                        .fill(Color(uiColor: .systemGray6))
                )
                .accessibilityLabel(realNumber)

            Text(countdownText)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(Localization.securityNote)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Constants.largePadding)

            Spacer()

            Button(Localization.cancel, action: onCancel)
                .buttonStyle(SecondaryButtonStyle())
                .padding(.horizontal, Constants.standardPadding)
                .padding(.bottom, Constants.standardPadding)
        }
        .onReceive(timer) { now = $0 }
    }

    private var subtitleLabel: String {
        switch subtitle {
        case .host: return Localization.subtitleLabelSelfHosted
        case .email: return Localization.subtitleLabelWPCom
        }
    }

    private var subtitleValue: String {
        switch subtitle {
        case .host(let host): return host
        case .email(let email): return email
        }
    }

    private var countdownText: String {
        let remainingSeconds = max(Constants.minimumRemainingSeconds, Int(expiresAt.timeIntervalSince(now)))
        return String(format: Localization.countdown, remainingSeconds)
    }
}

// MARK: - Localization

private extension QRLoginNumberMatchView {
    enum Constants {
        static let countdownTimerInterval: TimeInterval = 1
        static let minimumRemainingSeconds = 0
        static let smallSpacing: CGFloat = 8
        static let standardSpacing: CGFloat = 24
        static let mediumPadding: CGFloat = 16
        static let standardPadding: CGFloat = 24
        static let largePadding: CGFloat = 32
        static let subtitleCornerRadius: CGFloat = 12
        static let numberCornerRadius: CGFloat = 16
        static let numberFontSize: CGFloat = 56
    }

    enum Localization {
        static let title = NSLocalizedString(
            "qrLogin.numberMatch.title",
            value: "Confirm sign-in",
            comment: "Title on the QR number-match screen."
        )
        static let subtitleLabelSelfHosted = NSLocalizedString(
            "qrLogin.numberMatch.subtitle.selfHosted",
            value: "You're signing in to",
            comment: "Label above the site host on the QR number-match screen."
        )
        static let subtitleLabelWPCom = NSLocalizedString(
            "qrLogin.numberMatch.subtitle.wpCom",
            value: "You're signing in as",
            comment: "Label above the wp.com email on the QR number-match screen."
        )
        static let tapHint = NSLocalizedString(
            "qrLogin.numberMatch.tapHint",
            value: "Tap this number on your computer to finish.",
            comment: "Instruction above the 3-digit number on the QR number-match screen."
        )
        static let securityNote = NSLocalizedString(
            "qrLogin.numberMatch.securityNote",
            value: "Both screens must show the same number for sign-in to complete.",
            comment: "Security note on the QR number-match screen."
        )
        static let cancel = NSLocalizedString(
            "qrLogin.numberMatch.cancel",
            value: "Cancel",
            comment: "Button to cancel sign-in from the QR number-match screen."
        )
        static let countdown = NSLocalizedString(
            "qrLogin.numberMatch.countdown",
            value: "Expires in %1$ds",
            comment: "Countdown label on the QR number-match screen. %1$d is the number of seconds remaining."
        )
    }
}
