import SwiftUI

/// Warning shown when a `woocommerce://qr-login` deep link arrives while the
/// merchant is already signed in. Confirming signs the merchant out
/// and resumes the QR sign-in; cancelling keeps the current session.
struct QRLoginSessionReplaceView: View {
    /// Called when the merchant chooses to sign out and continue.
    let onConfirm: () -> Void
    /// Called when the merchant keeps the current session.
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: Constants.zeroSpacing) {
            ScrollView {
                VStack(spacing: Constants.contentSpacing) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: Constants.iconSize, height: Constants.iconSize)
                        .foregroundColor(Color(uiColor: .warning))
                        .padding(Constants.iconPadding)
                        .background(
                            Circle().fill(Color(uiColor: .warning).opacity(Constants.warningBackgroundOpacity))
                        )
                        .padding(.top, Constants.topPadding)
                        .accessibilityHidden(true)

                    Text(Localization.title)
                        .font(.title)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text(Localization.body)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Constants.largePadding)
                }
            }

            VStack(spacing: Constants.buttonSpacing) {
                Button(Localization.confirm, action: onConfirm)
                    .buttonStyle(PrimaryButtonStyle())

                Button(Localization.cancel, action: onCancel)
                    .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, Constants.standardPadding)
            .padding(.bottom, Constants.standardPadding)
        }
        .background(Color(uiColor: .systemBackground))
    }
}

// MARK: - Localization

private extension QRLoginSessionReplaceView {
    enum Constants {
        static let zeroSpacing: CGFloat = 0
        static let buttonSpacing: CGFloat = 12
        static let contentSpacing: CGFloat = 20
        static let standardPadding: CGFloat = 24
        static let largePadding: CGFloat = 32
        static let iconSize: CGFloat = 44
        static let iconPadding: CGFloat = 22
        static let topPadding: CGFloat = 48
        static let warningBackgroundOpacity = 0.15
    }

    enum Localization {
        static let title = NSLocalizedString(
            "qrLogin.sessionReplace.title",
            value: "You're already signed in",
            comment: "Title of the QR-login warning shown when a signed-in merchant scans a sign-in QR code."
        )
        static let body = NSLocalizedString(
            "qrLogin.sessionReplace.body",
            value: "Continuing will sign you out of your current session and start a new sign-in.",
            comment: "Body of the QR-login warning shown when a signed-in merchant scans a sign-in QR code."
        )
        static let confirm = NSLocalizedString(
            "qrLogin.sessionReplace.confirm",
            value: "Continue and sign out",
            comment: "Primary CTA on the QR-login session-replace warning — signs out and resumes the QR sign-in."
        )
        static let cancel = NSLocalizedString(
            "qrLogin.sessionReplace.cancel",
            value: "Cancel",
            comment: "Secondary CTA on the QR-login session-replace warning — keeps the current session."
        )
    }
}
