import SwiftUI

/// Fullscreen "Signing you in…" + spinner shown during the three logical
/// authenticating phases (scan, exchange, complete) per spec §4.5.
struct QRLoginAuthenticatingView: View {
    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .controlSize(.large)
                .tint(Color(uiColor: .accent))

            Text(Localization.title)
                .font(.title3)
                .foregroundColor(.secondary)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}

private extension QRLoginAuthenticatingView {
    enum Localization {
        static let title = NSLocalizedString(
            "qrLogin.authenticating.title",
            value: "Signing you in…",
            comment: "Title on the QR-login authenticating screen."
        )
    }
}
