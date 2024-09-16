import SwiftUI

final class CardReaderConnectionViewModel: ObservableObject {
    @Published private(set) var connectionStatus: CardReaderConnectionStatus = .disconnected
    private let cardPresentPayment: CardPresentPaymentFacade

    init(cardPresentPayment: CardPresentPaymentFacade) {
        self.cardPresentPayment = cardPresentPayment
        observeConnectedReaderForStatus()
    }

    func connectReader() {
        guard connectionStatus == .disconnected else {
            return
        }
        Task { @MainActor in
            do {
                let _ = try await cardPresentPayment.connectReader(using: .bluetooth)
            } catch {
                DDLogError("🔴 POS reader connection error: \(error)")
            }
        }
    }

    func disconnectReader() {
        guard connectionStatus == .connected else {
            return
        }
        connectionStatus = .disconnecting
        Task { @MainActor in
            await cardPresentPayment.disconnectReader()
        }
    }
}

private extension CardReaderConnectionViewModel {
    func observeConnectedReaderForStatus() {
        cardPresentPayment.connectedReaderPublisher
            .map { connectedReader in
                connectedReader == nil ? .disconnected: .connected
            }
            .assign(to: &$connectionStatus)
    }
}
