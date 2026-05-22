import Foundation

/// All the user-facing failure variants the QR-login flow can surface, drawn
/// from spec §8.
///
/// Each variant encodes:
///   - the *kind* (drives the title / body / illustration choice in the UI)
///   - the *primary CTA action* (retry-the-failed-phase vs. scan-a-new-code)
///   - the *phase* the failure originated in (used for analytics and to
///     know which Remote method to re-run on retry — §6.1).
///
/// The user-facing copy (title / body / button labels) lives in the UI layer
/// (`QRLoginErrorView`); this type only carries the structured kind / phase /
/// CTA so it stays free of localised strings.
struct QRLoginUserFacingError: Error, Equatable {

    enum Kind: Equatable {
        // Payload / scanner (raised before the network flow starts).
        /// "Not a WooCommerce code".
        case invalidPayload
        /// "That's the install QR".
        case installQR
        /// "Couldn't read that code".
        case scannerFailure

        // Token / server.
        /// "Code expired".
        case codeExpired
        /// "This store can't complete QR login" — self-hosted only.
        case storeUnsupported
        /// "Too many attempts".
        case rateLimited
        /// "Couldn't reach your store".
        case network
        /// "Something went wrong".
        case unexpected
        /// "Code already used".
        case codeAlreadyUsed

        // Poll terminal outcomes.
        /// "Sign-in denied".
        case signInDenied
        /// "Sign-in timed out".
        case signInTimedOut
        /// "Sign-in interrupted".
        case signInInterrupted
        /// "Already signed in elsewhere" — wp.com only.
        case alreadySignedInElsewhere

        // Self-hosted post-exchange.
        /// "Sign-in failed" — site fetch auth failure.
        case siteAuthFailure
        /// "Not a WooCommerce store".
        case notAWooSite
        /// "Permission needed" — eligibility check failed.
        case userNotEligible
    }

    enum Phase: Equatable {
        case scan
        case poll
        case exchange
        /// Self-hosted post-exchange site setup (site fetch, AP save,
        /// eligibility, store selection).
        case postExchange
        /// Failures that happened before the network flow started — payload
        /// parse, install-QR detection, scanner pipeline.
        case prelude
    }

    enum PrimaryAction: Equatable {
        /// "Try again" — re-runs the failed step (`scan`, `poll`, or
        /// `exchange`) per spec §6.1.
        case retryFailedPhase
        /// "Scan a new code" — returns to the scanner. In deep-link mode the
        /// caller exits the QR-login surface instead.
        case scanAgain
    }

    let kind: Kind
    let phase: Phase
    let primaryAction: PrimaryAction

    init(kind: Kind, phase: Phase, primaryAction: PrimaryAction) {
        self.kind = kind
        self.phase = phase
        self.primaryAction = primaryAction
    }
}
