import SwiftUI

/// Root view for the live QR-login flow (post-scan). Binds to
/// `QRLoginViewModel.state` and switches between the authenticating, number-
/// match, and error sub-views.
///
/// Done / idle states are forwarded to the coordinator via callbacks — when
/// the view model reaches `.done`, the coordinator drives navigation to the
/// home screen; when it returns to `.idle` after a cancel-from-number-match,
/// the coordinator pops back to the scanner.
struct QRLoginHostView: View {
    @State var viewModel: QRLoginViewModel
    let onDone: () -> Void
    let onIdle: () -> Void
    let onEnterSiteURLTapped: () -> Void

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .idle:
                QRLoginAuthenticatingView()
                    .task { onIdle() }
            case .authenticating:
                QRLoginAuthenticatingView()
            case let .numberMatch(scan):
                QRLoginNumberMatchView(
                    realNumber: scan.realNumber,
                    expiresAt: Date().addingTimeInterval(TimeInterval(scan.expiresInSeconds)),
                    subtitle: scan.subtitle,
                    onCancel: { viewModel.cancelFromNumberMatch() }
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
