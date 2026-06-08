import SwiftUI

/// Fullscreen error variant for any failure surfaced by the QR-login flow.
/// Title / body / primary CTA come from the user-facing error variant; the
/// secondary CTA is always "Enter site URL instead".
struct QRLoginErrorView: View {
    let error: QRLoginUserFacingError
    let onPrimaryTapped: () -> Void
    let onEnterSiteURLTapped: () -> Void

    var body: some View {
        VStack(spacing: Constants.zeroSpacing) {
            Spacer(minLength: Constants.standardPadding)

            VStack(spacing: Constants.contentSpacing) {
                Image(systemName: errorContent.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                    .foregroundColor(Color(uiColor: .systemRed))
                    .accessibilityHidden(true)

                Text(errorContent.title)
                    .font(.title)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(errorContent.body)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Constants.largePadding)
            }

            Spacer(minLength: Constants.standardPadding)

            VStack(spacing: Constants.buttonSpacing) {
                Button(primaryCTA, action: onPrimaryTapped)
                    .buttonStyle(PrimaryButtonStyle())

                Button(Localization.enterSiteURL, action: onEnterSiteURLTapped)
                    .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, Constants.standardPadding)
            .padding(.bottom, Constants.standardPadding)
        }
    }
}

// MARK: - Content

private extension QRLoginErrorView {

    struct Content {
        let iconName: String
        let title: String
        let body: String

        init(iconName: String = "exclamationmark.triangle", title: String, body: String) {
            self.iconName = iconName
            self.title = title
            self.body = body
        }
    }

    var errorContent: Content {
        switch error.kind {
        case .invalidPayload:
            Content(iconName: "qrcode.viewfinder",
                    title: Localization.invalidPayloadTitle,
                    body: Localization.invalidPayloadBody)
        case .installQR:
            Content(iconName: "qrcode.viewfinder",
                    title: Localization.installQRTitle,
                    body: Localization.installQRBody)
        case .scannerFailure:
            Content(iconName: "qrcode.viewfinder",
                    title: Localization.scannerFailureTitle,
                    body: Localization.scannerFailureBody)
        case .network:
            Content(iconName: "wifi.slash",
                    title: Localization.networkTitle,
                    body: Localization.networkBody)
        case .rateLimited:
            Content(iconName: "clock.badge.exclamationmark",
                    title: Localization.rateLimitedTitle,
                    body: Localization.rateLimitedBody)
        case .codeExpired:
            Content(title: Localization.codeExpiredTitle,
                    body: Localization.codeExpiredBody)
        case .storeUnsupported:
            Content(title: Localization.storeUnsupportedTitle,
                    body: Localization.storeUnsupportedBody)
        case .unexpected:
            Content(title: Localization.unexpectedTitle,
                    body: Localization.unexpectedBody)
        case .codeAlreadyUsed:
            Content(title: Localization.codeAlreadyUsedTitle,
                    body: Localization.codeAlreadyUsedBody)
        case .signInDenied:
            Content(title: Localization.signInDeniedTitle,
                    body: Localization.signInDeniedBody)
        case .signInTimedOut:
            Content(title: Localization.signInTimedOutTitle,
                    body: Localization.signInTimedOutBody)
        case .signInInterrupted:
            Content(title: Localization.signInInterruptedTitle,
                    body: Localization.signInInterruptedBody)
        case .alreadySignedInElsewhere:
            Content(title: Localization.alreadySignedInElsewhereTitle,
                    body: Localization.alreadySignedInElsewhereBody)
        case .siteAuthFailure:
            Content(title: Localization.siteAuthFailureTitle,
                    body: Localization.siteAuthFailureBody)
        case .notAWooSite:
            Content(title: Localization.notAWooSiteTitle,
                    body: Localization.notAWooSiteBody)
        case .userNotEligible:
            Content(title: Localization.userNotEligibleTitle,
                    body: Localization.userNotEligibleBody)
        }
    }

    var primaryCTA: String {
        switch error.primaryAction {
        case .retryFailedPhase:
            // Scanner-failure is treated as retryable but its CTA is "Try
            // again" to scan again — same string applies.
            return Localization.tryAgain
        case .scanAgain:
            return Localization.scanNewCode
        }
    }
}

// MARK: - Localization

private extension QRLoginErrorView {
    enum Constants {
        static let zeroSpacing: CGFloat = 0
        static let buttonSpacing: CGFloat = 12
        static let contentSpacing: CGFloat = 20
        static let standardPadding: CGFloat = 24
        static let largePadding: CGFloat = 32
        static let iconSize: CGFloat = 88
    }

    enum Localization {
        // Titles
        static let invalidPayloadTitle = NSLocalizedString(
            "qrLogin.error.invalidPayload.title",
            value: "Not a WooCommerce code",
            comment: "QR-login error title when the scanned payload isn't recognised."
        )
        static let installQRTitle = NSLocalizedString(
            "qrLogin.error.installQR.title",
            value: "That's the install QR",
            comment: "QR-login error title when the user scans the wp-admin install QR."
        )
        static let scannerFailureTitle = NSLocalizedString(
            "qrLogin.error.scannerFailure.title",
            value: "Couldn't read that code",
            comment: "QR-login error title when the scanner pipeline fails."
        )
        static let codeExpiredTitle = NSLocalizedString(
            "qrLogin.error.codeExpired.title",
            value: "Code expired",
            comment: "QR-login error title when the token was rejected by the server."
        )
        static let storeUnsupportedTitle = NSLocalizedString(
            "qrLogin.error.storeUnsupported.title",
            value: "This store can't complete QR login",
            comment: "QR-login error title when the store's plugin doesn't support the QR flow."
        )
        static let rateLimitedTitle = NSLocalizedString(
            "qrLogin.error.rateLimited.title",
            value: "Too many attempts",
            comment: "QR-login error title for HTTP 429 responses."
        )
        static let networkTitle = NSLocalizedString(
            "qrLogin.error.network.title",
            value: "Couldn't reach your store",
            comment: "QR-login error title for transport failures."
        )
        static let unexpectedTitle = NSLocalizedString(
            "qrLogin.error.unexpected.title",
            value: "Something went wrong",
            comment: "QR-login error title for 5xx / malformed / unmapped server responses."
        )
        static let codeAlreadyUsedTitle = NSLocalizedString(
            "qrLogin.error.codeAlreadyUsed.title",
            value: "Code already used",
            comment: "QR-login error title for HTTP 409 — another device already scanned this QR."
        )
        static let signInDeniedTitle = NSLocalizedString(
            "qrLogin.error.signInDenied.title",
            value: "Sign-in denied",
            comment: "QR-login error title when the merchant denied the sign-in in the desktop browser."
        )
        static let signInTimedOutTitle = NSLocalizedString(
            "qrLogin.error.signInTimedOut.title",
            value: "Sign-in timed out",
            comment: "QR-login error title when the merchant didn't confirm in time."
        )
        static let signInInterruptedTitle = NSLocalizedString(
            "qrLogin.error.signInInterrupted.title",
            value: "Sign-in interrupted",
            comment: "QR-login error title for invalid_exchange_grant / wp.com exchange 404."
        )
        static let alreadySignedInElsewhereTitle = NSLocalizedString(
            "qrLogin.error.alreadySignedInElsewhere.title",
            value: "Already signed in elsewhere",
            comment: "QR-login error title for wp.com consumed / already_consumed."
        )
        static let siteAuthFailureTitle = NSLocalizedString(
            "qrLogin.error.siteAuthFailure.title",
            value: "Sign-in failed",
            comment: "QR-login error title when post-exchange site fetch fails."
        )
        static let notAWooSiteTitle = NSLocalizedString(
            "qrLogin.error.notAWooSite.title",
            value: "Not a WooCommerce store",
            comment: "QR-login error title when the fetched site doesn't have WooCommerce installed."
        )
        static let userNotEligibleTitle = NSLocalizedString(
            "qrLogin.error.userNotEligible.title",
            value: "Permission needed",
            comment: "QR-login error title when the user's role doesn't allow app access."
        )

        // Bodies
        static let invalidPayloadBody = NSLocalizedString(
            "qrLogin.error.invalidPayload.body",
            value: "This QR isn't a WooCommerce login code. Generate a new one from your store and try again.",
            comment: "QR-login error body when the scanned payload isn't recognised."
        )
        static let installQRBody = NSLocalizedString(
            "qrLogin.error.installQR.body",
            value: "The app's already installed — this QR installs it. In wp-admin, tap the App is installed " +
                "button to reveal the sign-in QR. Or visit woo.com/mobilelogin on your computer.",
            comment: "QR-login error body when the user scans the wp-admin install QR."
        )
        static let scannerFailureBody = NSLocalizedString(
            "qrLogin.error.scannerFailure.body",
            value: "We couldn't read that QR code. Please try again.",
            comment: "QR-login error body when the scanner pipeline fails."
        )
        static let codeExpiredBody = NSLocalizedString(
            "qrLogin.error.codeExpired.body",
            value: "That code expired or has already been used. Generate a new one in your store.",
            comment: "QR-login error body for the token-rejected case."
        )
        static let storeUnsupportedBody = NSLocalizedString(
            "qrLogin.error.storeUnsupported.body",
            value: "Your WooCommerce plugin doesn't support QR login. Please update WooCommerce on your store " +
                "and try again, or sign in by entering your site URL.",
            comment: "QR-login error body for the store-can't-complete case."
        )
        static let rateLimitedBody = NSLocalizedString(
            "qrLogin.error.rateLimited.body",
            value: "Please wait a few minutes and try again.",
            comment: "QR-login error body for HTTP 429."
        )
        static let networkBody = NSLocalizedString(
            "qrLogin.error.network.body",
            value: "Check your connection and try again.",
            comment: "QR-login error body for transport failures."
        )
        static let unexpectedBody = NSLocalizedString(
            "qrLogin.error.unexpected.body",
            value: "Your store returned an unexpected error. Please try again in a moment.",
            comment: "QR-login error body for 5xx / malformed responses."
        )
        static let codeAlreadyUsedBody = NSLocalizedString(
            "qrLogin.error.codeAlreadyUsed.body",
            value: "That code has already been scanned. Generate a new one in your store.",
            comment: "QR-login error body when another device already scanned the QR."
        )
        static let signInDeniedBody = NSLocalizedString(
            "qrLogin.error.signInDenied.body",
            value: "For your security, this sign-in attempt was cancelled. Generate a new code in your store to try again.",
            comment: "QR-login error body when sign-in was explicitly denied."
        )
        static let signInTimedOutBody = NSLocalizedString(
            "qrLogin.error.signInTimedOut.body",
            value: "You didn't confirm in time. Generate a new code in your store and try again.",
            comment: "QR-login error body when the merchant didn't confirm in time."
        )
        static let signInInterruptedBody = NSLocalizedString(
            "qrLogin.error.signInInterrupted.body",
            value: "Your sign-in was interrupted. Generate a new code in your store and try again.",
            comment: "QR-login error body for invalid_exchange_grant / wp.com exchange 404."
        )
        static let alreadySignedInElsewhereBody = NSLocalizedString(
            "qrLogin.error.alreadySignedInElsewhere.body",
            value: "This sign-in was already completed on another device. Generate a new code if you need to try again.",
            comment: "QR-login error body for wp.com consumed / already_consumed."
        )
        static let siteAuthFailureBody = NSLocalizedString(
            "qrLogin.error.siteAuthFailure.body",
            value: "We couldn't authenticate with your store. Please try again.",
            comment: "QR-login error body when post-exchange site fetch fails authentication."
        )
        static let notAWooSiteBody = NSLocalizedString(
            "qrLogin.error.notAWooSite.body",
            value: "This site doesn't have WooCommerce installed.",
            comment: "QR-login error body when the fetched site doesn't have WooCommerce installed."
        )
        static let userNotEligibleBody = NSLocalizedString(
            "qrLogin.error.userNotEligible.body",
            value: "Your account doesn't have permission to use the app for this store.",
            comment: "QR-login error body when the user's role doesn't allow app access."
        )

        // CTAs
        static let tryAgain = NSLocalizedString(
            "qrLogin.error.tryAgain",
            value: "Try again",
            comment: "Primary CTA on a retryable QR-login error."
        )
        static let scanNewCode = NSLocalizedString(
            "qrLogin.error.scanNewCode",
            value: "Scan a new code",
            comment: "Primary CTA on a non-retryable QR-login error."
        )
        static let enterSiteURL = NSLocalizedString(
            "qrLogin.error.enterSiteURL",
            value: "Enter site URL instead",
            comment: "Secondary CTA on every QR-login error — falls back to the site-address login."
        )
    }
}
