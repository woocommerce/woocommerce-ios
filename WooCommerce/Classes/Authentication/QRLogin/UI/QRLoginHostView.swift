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
    /// Called when the merchant cancels from the number-match screen — the
    /// coordinator pops back to the scanner (camera mode) or exits (deep-link
    /// mode). Wired directly to the cancel action rather than observed off the
    /// `.idle` state, so the initial `.idle` (before `start()`) never triggers
    /// navigation.
    let onCancel: () -> Void
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
            case let .error(error):
                QRLoginErrorView(
                    error: error,
                    onPrimaryTapped: { Task { await viewModel.retry() } },
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
