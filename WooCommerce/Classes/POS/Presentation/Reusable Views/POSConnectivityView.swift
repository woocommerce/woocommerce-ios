import SwiftUI
import Combine

struct POSConnectivityView: View {
    let connectivityObserver: ConnectivityObserver = ServiceLocator.connectivityObserver
    @State private var isVisible = false
    @State private var cancellable: AnyCancellable?

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
            updateVisibility(connectivityObserver.currentStatus)
            cancellable = connectivityObserver.statusPublisher
                .receive(on: DispatchQueue.main)
                .sink { status in
                    updateVisibility(status)
                }
        }
    }

    @ViewBuilder private var noConnectionBanner: some View {
        HStack(spacing: Constants.spacing) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundColor(Color(.text.inverted))
                .font(.posDetailEmphasized)

            Text(Localization.title)
                .foregroundColor(Color(.text.inverted))
                .font(.posDetailEmphasized)
        }
        .padding(.vertical, Constants.verticalPadding)
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(minHeight: Constants.height)
        .background(Color(.systemGray6.inverted))
        .cornerRadius(Constants.cornerRadius)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func updateVisibility(_ status: ConnectivityStatus) {
        isVisible = (status == .notReachable)
    }
}

private extension POSConnectivityView {
    enum Constants {
        static let cornerRadius: CGFloat = 16
        static let height: CGFloat = 64
        static let spacing: CGFloat = 16
        static let horizontalPadding: CGFloat = 24
        static let verticalPadding: CGFloat = 8
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
