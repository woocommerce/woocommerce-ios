import SwiftUI

/// Root view for the live QR-login flow (post-scan). Binds to
/// `QRLoginViewModel.state` and switches between the authenticating, number-
/// match, and error sub-views.
///
/// Navigation out of this view is driven by callbacks: reaching `.done`
/// invokes `onDone` so the coordinator routes to the home screen, and the
/// number-match Cancel button invokes `onCancel` so the coordinator pops back
/// to the scanner (camera mode) or exits (deep-link mode).
struct QRLoginHostView: View {
    @State var viewModel: QRLoginViewModel
    /// Called when the merchant is signed in (state reaches `.done`).
    let onDone: () -> Void
    /// Called when the wp.com flow hands the magic link to an in-app browser
    /// (state reaches `.handedOff`). Sign-in then completes via the magic-login
    /// redirect, so the coordinator just dismisses the QR-login surface — it
    /// must NOT route to the store picker (spec §10.1).
    let onMagicLinkHandedOff: () -> Void
    /// Called when the merchant cancels from the number-match screen — the
    /// coordinator pops back to the scanner (camera mode) or exits (deep-link
    /// mode). Wired directly to the cancel action rather than observed off the
    /// `.idle` state, so the initial `.idle` (before `start()`) never triggers
    /// navigation.
    let onCancel: () -> Void
    /// Called when the merchant taps the "Scan a new code" CTA on a
    /// non-retryable error — the coordinator returns them to a fresh scanner
    /// (camera mode) or exits the QR-login surface (deep-link mode). Retryable
    /// errors re-run the failed phase via the view model instead.
    let onScanAgain: () -> Void
    let onEnterSiteURLTapped: () -> Void

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .idle, .authenticating:
                QRLoginAuthenticatingView()
            case let .numberMatch(scan):
                QRLoginNumberMatchView(
                    realNumber: scan.realNumber,
                    expiresAt: Date().addingTimeInterval(TimeInterval(scan.expiresInSeconds)),
                    subtitle: scan.subtitle,
                    onCancel: {
                        viewModel.cancelFromNumberMatch()
                        onCancel()
                    }
                )
            case .done:
                QRLoginAuthenticatingView()
                    .task { onDone() }
            case .handedOff:
                QRLoginAuthenticatingView()
                    .task { onMagicLinkHandedOff() }
            case let .error(error):
                QRLoginErrorView(
                    error: error,
                    onPrimaryTapped: {
                        // The primary CTA's meaning depends on the error: a
                        // retryable error re-runs the failed phase, a
                        // non-retryable one ("Scan a new code") hands back to
                        // the coordinator to start a fresh scan (spec §6.1).
                        switch error.primaryAction {
                        case .retryFailedPhase:
                            Task { await viewModel.retry() }
                        case .scanAgain:
                            onScanAgain()
                        }
                    },
                    onEnterSiteURLTapped: onEnterSiteURLTapped
                )
            }
        }
        .task {
            // Idempotent — guarded inside the view model.
            await viewModel.start()
        }
    }
}
