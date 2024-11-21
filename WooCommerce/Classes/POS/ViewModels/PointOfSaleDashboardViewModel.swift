import SwiftUI
import Combine

final class PointOfSaleDashboardViewModel: ObservableObject {
    private let connectivityObserver: ConnectivityObserver

    @Published var showExitPOSModal: Bool = false
    @Published var showSupport: Bool = false
    @Published var showsConnectivityError: Bool = false

    private var cancellables: Set<AnyCancellable> = []

    init(connectivityObserver: ConnectivityObserver) {
        self.connectivityObserver = connectivityObserver

        observeConnectivity()
    }
}

private extension PointOfSaleDashboardViewModel {
    func observeConnectivity() {
        connectivityObserver.statusPublisher
            .removeDuplicates()
            .map { connectivityStatus in
                return connectivityStatus == .notReachable
            }
            .assign(to: &$showsConnectivityError)
    }
}
