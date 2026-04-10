import SwiftUI
import Combine
import enum WooFoundation.ConnectivityStatus

struct POSConnectivityView: View {
    @State private var isVisible = false
    @State private var cancellable: AnyCancellable?
    @Environment(\.posConnectivityProvider) private var provider

    var body: some View {
        ZStack(alignment: .top) {
            if isVisible {
                noConnectionBanner
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
        HStack(spacing: Constants.spacing) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundColor(Color.posOnSecondaryContainer)
                .font(.posBodySmallBold())

            Text(Localization.title)
                .foregroundColor(Color.posOnSecondaryContainer)
                .font(.posBodySmallBold())
        }
        .padding(.vertical, Constants.verticalPadding)
        .padding(.horizontal, Constants.horizontalPadding)
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
        static let spacing: CGFloat = POSSpacing.medium
        static let horizontalPadding: CGFloat = POSPadding.large
        static let verticalPadding: CGFloat = POSPadding.small
        static let connectivityAnimationDuration: CGFloat = 1.0
    }

    enum Localization {
        static let title = NSLocalizedString(
            "pos.connectivity.title",
            value: "No internet connection",
            comment: "Title shown on a toast view that appears when there's no internet connection"
        )
    }
}

#Preview {
    // To enable preview, set `isVisible` to `true` and comment out `onAppear` block.
    POSConnectivityView()
}
