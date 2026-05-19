import SwiftUI

/// QR-login prologue. Shown when the user taps the primary "Log in" CTA and
/// QR login is available (spec §4.1).
///
/// Three actions reach the coordinator via the callbacks:
///   - Primary "Scan QR code" → coordinator requests camera permission and,
///     if granted, presents the scanner.
///   - Secondary "No computer? Log in with site address" → coordinator falls
///     back to the legacy site-address login flow.
///   - Top-right help icon → coordinator opens Help & Support with the
///     `LOGIN_WITH_QR_CODE` origin.
struct QRLoginPrologueView: View {
    let onScanTapped: () -> Void
    let onSiteAddressTapped: () -> Void
    let onHelpTapped: () -> Void
    let onURLTapped: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onHelpTapped) {
                    Image(systemName: "questionmark.circle")
                        .imageScale(.large)
                        .accessibilityLabel(Localization.helpAccessibility)
                }
                .padding(.trailing)
                .padding(.top, 8)
            }

            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "qrcode.viewfinder")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .foregroundColor(Color(uiColor: .brand))
                        .padding(.top, 32)
                        .accessibilityHidden(true)

                    Text(Localization.title)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text(Localization.subtitle)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button(action: onURLTapped) {
                        HStack(spacing: 8) {
                            Image(systemName: "desktopcomputer")
                            Text(verbatim: Localization.urlPillValue)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(uiColor: .systemGray6))
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Localization.urlPillAccessibilityHint)

                    Text(Localization.stepHint)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }

            VStack(spacing: 12) {
                Button(action: onScanTapped) {
                    Text(Localization.scanCTA)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Color(uiColor: .accent))

                Button(action: onSiteAddressTapped) {
                    Text(Localization.fallbackCTA)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Localization

private extension QRLoginPrologueView {
    enum Localization {
        static let title = NSLocalizedString(
            "qrLogin.prologue.title",
            value: "Scan to log in",
            comment: "Title on the QR-login prologue screen."
        )
        static let subtitle = NSLocalizedString(
            "qrLogin.prologue.subtitle",
            value: "On your computer, visit:",
            comment: "Subtitle on the QR-login prologue, introducing the URL the user should visit."
        )
        static let urlPillValue = "woo.com/mobilelogin"
        static let urlPillAccessibilityHint = NSLocalizedString(
            "qrLogin.prologue.urlPill.accessibilityHint",
            value: "Copies the URL to the clipboard.",
            comment: "Accessibility hint for the tappable URL pill on the QR-login prologue."
        )
        static let stepHint = NSLocalizedString(
            "qrLogin.prologue.stepHint",
            value: "Then scan the QR code that appears.",
            comment: "Hint below the URL pill on the QR-login prologue."
        )
        static let scanCTA = NSLocalizedString(
            "qrLogin.prologue.scanCTA",
            value: "Scan QR code",
            comment: "Primary call-to-action on the QR-login prologue."
        )
        static let fallbackCTA = NSLocalizedString(
            "qrLogin.prologue.fallbackCTA",
            value: "No computer? Log in with site address",
            comment: "Secondary call-to-action on the QR-login prologue."
        )
        static let helpAccessibility = NSLocalizedString(
            "qrLogin.prologue.help.accessibility",
            value: "Help",
            comment: "Accessibility label for the help button on the QR-login prologue."
        )
    }
}

#if DEBUG
#Preview {
    QRLoginPrologueView(
        onScanTapped: {},
        onSiteAddressTapped: {},
        onHelpTapped: {},
        onURLTapped: {}
    )
}
#endif
