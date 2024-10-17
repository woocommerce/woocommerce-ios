import SwiftUI

final class CardReaderConnectionViewModel: ObservableObject {
    @Published private(set) var connectionStatus: CardPresentPaymentReaderConnectionStatus = .disconnected
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

    func connectRemoteReader() {
        guard connectionStatus == .disconnected else {
            return
        }
        Task { @MainActor in
            do {
                let _ = try await cardPresentPayment.connectReader(using: .remoteTapToPay)
            } catch {
                DDLogError("🔴 POS tap to pay connection error: \(error)")
            }
        }
    }

    func disconnectReader() {
        guard case .connected = connectionStatus else {
            return
        }
        Task { @MainActor in
            await cardPresentPayment.disconnectReader()
        }
    }
}

private extension CardReaderConnectionViewModel {
    func observeConnectedReaderForStatus() {
        cardPresentPayment.readerConnectionStatusPublisher
            .assign(to: &$connectionStatus)
    }
}
