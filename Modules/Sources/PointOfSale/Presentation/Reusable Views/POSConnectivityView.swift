import SwiftUI
import Combine
import enum WooFoundation.ConnectivityStatus

struct POSConnectivityView: View {
    @Environment(\.posMetrics) private var metrics
    @State private var isVisible = false
    @State private var cancellable: AnyCancellable?
    @Environment(\.posConnectivityProvider) private var provider

    var body: some View {
        ZStack(alignment: .top) {
            if isVisible {
                noConnectionBanner
                    .padding(.top, metrics.padding.small)
                    .transition(.asymmetric(insertion: .push(from: .top), removal: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: Constants.connectivityAnimationDuration),
                   value: isVisible)
        .onAppear {
            updateVisibility(provider.connectivityObserver.currentStatus)
            cancellable = provider.connectivityObserver.statusPublisher
                .receive(on: DispatchQueue.main)
                .sink { status in
                    updateVisibility(status)
                }
        }
    }

    @ViewBuilder private var noConnectionBanner: some View {
        HStack(spacing: metrics.spacing.medium) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundColor(Color.posOnSecondaryContainer)
                .font(.posBodySmallBold())

            Text(POSConnectivityErrorNotice.title)
                .foregroundColor(Color.posOnSecondaryContainer)
                .font(.posBodySmallBold())
        }
        .padding(.vertical, metrics.padding.small)
        .padding(.horizontal, metrics.padding.large)
        .frame(minHeight: Constants.height)
        .background(Color.posSecondaryContainer)
        .cornerRadius(Constants.cornerRadius)
        .posShadow(.medium, cornerRadius: Constants.cornerRadius)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func updateVisibility(_ status: ConnectivityStatus) {
        isVisible = (status == .notReachable)
    }
}

private extension POSConnectivityView {
    enum Constants {
        static let cornerRadius: CGFloat = POSCornerRadiusStyle.large.value
        static let height: CGFloat = 64
        static let connectivityAnimationDuration: CGFloat = 1.0
    }
}

#Preview {
    // To enable preview, set `isVisible` to `true` and comment out `onAppear` block.
    POSConnectivityView()
}
