import SwiftUI

/// Warning shown when a `woocommerce://qr-login` deep link arrives while the
/// merchant is already signed in (spec §4.4). Confirming signs the merchant out
/// and resumes the QR sign-in; cancelling keeps the current session.
struct QRLoginSessionReplaceView: View {
    /// Called when the merchant chooses to sign out and continue.
    let onConfirm: () -> Void
    /// Called when the merchant keeps the current session.
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .foregroundColor(Color(uiColor: .warning))
                        .padding(22)
                        .background(
                            Circle().fill(Color(uiColor: .warning).opacity(0.15))
                        )
                        .padding(.top, 48)
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
                        .padding(.horizontal, 32)
                }
            }

            VStack(spacing: 12) {
                Button(action: onConfirm) {
                    Text(Localization.confirm)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Color(uiColor: .accent))

                Button(action: onCancel) {
                    Text(Localization.cancel)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(uiColor: .systemBackground))
    }
}

// MARK: - Localization

private extension QRLoginSessionReplaceView {
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
