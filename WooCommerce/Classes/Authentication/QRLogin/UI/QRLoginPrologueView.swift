import SwiftUI
import UIKit

/// QR-login prologue. Pushed onto the login navigation stack when the user taps
/// the primary "Log in" CTA and QR login is available.
///
/// Two actions reach the coordinator via the callbacks:
///   - Primary "Scan QR code" → coordinator requests camera permission and,
///     if granted, presents the scanner.
///   - Secondary "No computer? Log in with site address" → coordinator falls
///     back to the legacy site-address login flow.
///
/// The screen reuses the standard login prologue's dark, bubble-textured
/// background so the QR entry point feels like part of the same login surface.
/// The shared navigation bar is hidden for this screen — Back and Help are
/// drawn here as light controls over the dark background.
struct QRLoginPrologueView: View {
    let onBackTapped: () -> Void
    let onHelpTapped: () -> Void
    let onScanTapped: () -> Void
    let onSiteAddressTapped: () -> Void
    let onURLTapped: () -> Void

    /// Drives the transient "copied" confirmation on the URL pill.
    @State private var didCopyURL = false

    var body: some View {
        VStack(spacing: Constants.zeroSpacing) {
            topBar

            ScrollView {
                VStack(spacing: Constants.standardSpacing) {
                    qrIcon

                    Text(Localization.title)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text(Localization.subtitle)
                        .font(.body)
                        .foregroundColor(.white.opacity(Constants.secondaryTextOpacity))
                        .multilineTextAlignment(.center)

                    urlPill

                    Text(Localization.stepHint)
                        .font(.body)
                        .foregroundColor(.white.opacity(Constants.secondaryTextOpacity))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.horizontal, Constants.largePadding)
                .padding(.vertical, Constants.standardPadding)
            }

            buttons
        }
        .background(prologueBackground)
    }

    /// Light Back / Help controls drawn where a navigation bar would sit, since
    /// the shared (purple-tinted) navigation bar is hidden for this screen. The
    /// insets line up with the standard navigation-bar items on the other
    /// QR-login screens.
    private var topBar: some View {
        HStack(spacing: Constants.zeroSpacing) {
            Button(action: onBackTapped) {
                Image(systemName: "chevron.backward")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: Constants.topBarControlSize, height: Constants.topBarControlSize)
            }
            .accessibilityLabel(Localization.back)

            Spacer()

            Button(action: onHelpTapped) {
                Text(Localization.help)
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(height: Constants.topBarControlSize)
                    .padding(.horizontal, Constants.mediumPadding)
            }
        }
    }

    private var qrIcon: some View {
        Image(systemName: "qrcode.viewfinder")
            .resizable()
            .scaledToFit()
            .frame(width: Constants.qrIconSize, height: Constants.qrIconSize)
            .foregroundColor(.white)
            .padding(Constants.qrIconPadding)
            .background(Circle().fill(Color.white.opacity(Constants.translucentControlOpacity)))
            .padding(.top, Constants.largePadding)
            .accessibilityHidden(true)
    }

    /// The URL the merchant should open on their computer — the most prominent
    /// step on the screen, so it uses a larger font. Tapping copies it and
    /// briefly confirms with a "copied" state.
    private var urlPill: some View {
        Button(action: copyURL) {
            HStack(spacing: Constants.smallSpacing) {
                Image(systemName: didCopyURL ? "checkmark.circle.fill" : "desktopcomputer")
                Group {
                    if didCopyURL {
                        Text(Localization.urlCopied)
                    } else {
                        Text(verbatim: Localization.urlPillValue)
                    }
                }
                .fontWeight(.semibold)
            }
            .font(.title3)
            .foregroundColor(.white)
            .padding(.horizontal, Constants.standardPadding)
            .padding(.vertical, Constants.urlPillVerticalPadding)
            .background(
                Capsule().fill(Color.white.opacity(Constants.translucentControlOpacity))
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint(Localization.urlPillAccessibilityHint)
    }

    private func copyURL() {
        onURLTapped()
        withAnimation { didCopyURL = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.copyConfirmationDelay) {
            withAnimation { didCopyURL = false }
        }
    }

    private var buttons: some View {
        VStack(spacing: Constants.mediumSpacing) {
            // White primary CTA — the accent purple would blend into the
            // purple background, so this mirrors the standard prologue's
            // white "Log In" button.
            Button(action: onScanTapped) {
                Text(Localization.scanCTA)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: Constants.primaryButtonHeight)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.buttonCornerRadius))
            }
            .buttonStyle(.plain)

            Button(action: onSiteAddressTapped) {
                Text(Localization.fallbackCTA)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Constants.smallSpacing)
            }
            .buttonStyle(.borderless)
            .controlSize(.large)
            .tint(.white)
        }
        .padding(.horizontal, Constants.standardPadding)
        .padding(.top, Constants.mediumSpacing)
        .padding(.bottom, Constants.standardPadding)
    }

    /// The standard login prologue's dark background — a tinted "bubbles" image
    /// over the prologue background colour. Rendered through a `UIImageView` so
    /// the tinted template asset draws correctly (a SwiftUI `Image` re-tints it).
    private var prologueBackground: some View {
        PrologueBubblesBackground()
            .ignoresSafeArea()
    }
}

// MARK: - Background

/// Bridges the standard login prologue's `UIImageView`-rendered background into
/// SwiftUI, so the QR prologue is visually identical to the main login surface.
private struct PrologueBubblesBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView(image: LoginPrologueViewController.backgroundImage)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = LoginPrologueViewController.backgroundColor
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}
}

// MARK: - Localization

private extension QRLoginPrologueView {
    enum Constants {
        static let zeroSpacing: CGFloat = 0
        static let smallSpacing: CGFloat = 8
        static let mediumSpacing: CGFloat = 12
        static let standardSpacing: CGFloat = 24
        static let mediumPadding: CGFloat = 16
        static let standardPadding: CGFloat = 24
        static let largePadding: CGFloat = 32
        static let secondaryTextOpacity = 0.7
        static let translucentControlOpacity = 0.12
        static let topBarControlSize: CGFloat = 44
        static let qrIconSize: CGFloat = 48
        static let qrIconPadding: CGFloat = 22
        static let urlPillVerticalPadding: CGFloat = 14
        static let copyConfirmationDelay: DispatchTimeInterval = .seconds(2)
        static let primaryButtonHeight: CGFloat = 50
        static let buttonCornerRadius: CGFloat = 8
    }

    enum Localization {
        static let back = NSLocalizedString(
            "qrLogin.prologue.back",
            value: "Back",
            comment: "Accessibility label for the back button on the QR-login prologue."
        )
        static let help = NSLocalizedString(
            "qrLogin.prologue.help",
            value: "Help",
            comment: "Help button on the QR-login prologue."
        )
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
        static let urlCopied = NSLocalizedString(
            "qrLogin.prologue.urlPill.copied",
            value: "Link copied!",
            comment: "Confirmation shown on the QR-login prologue URL pill after it is tapped to copy."
        )
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
    }
}

#if DEBUG
#Preview {
    QRLoginPrologueView(
        onBackTapped: {},
        onHelpTapped: {},
        onScanTapped: {},
        onSiteAddressTapped: {},
        onURLTapped: {}
    )
}
#endif
