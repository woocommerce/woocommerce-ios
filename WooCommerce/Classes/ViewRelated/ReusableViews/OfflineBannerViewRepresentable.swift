import SwiftUI
import Combine
import WooFoundation

/// Observable object that monitors connectivity status
///
final class ConnectivityMonitor: ObservableObject {
    @Published private(set) var isOffline: Bool = false

    private let connectivityObserver: ConnectivityObserver

    init(connectivityObserver: ConnectivityObserver = ServiceLocator.connectivityObserver) {
        self.connectivityObserver = connectivityObserver
        observeConnectivity()
    }

    private func observeConnectivity() {
        connectivityObserver.statusPublisher
            .map { status in
                status == .notReachable
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$isOffline)
    }
}

/// SwiftUI wrapper for UIKit OfflineBannerView
///
struct OfflineBannerViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> OfflineBannerView {
        let view = OfflineBannerView(frame: .zero)
        view.backgroundColor = .gray
        return view
    }

    func updateUIView(_ uiView: OfflineBannerView, context: Context) {
        // No updates needed
    }
}
