import SwiftUI
import Combine
import protocol Yosemite.POSItem

final class TotalsViewModel: ObservableObject, TotalsViewModelProtocol {

    @ObservedObject var posModel: PointOfSaleAggregateModel

    var isShimmering: Bool {
        posModel.orderState.isSyncing
    }

    private let cardPresentPaymentService: CardPresentPaymentFacade

    init(posModel: PointOfSaleAggregateModel,
         cardPresentPaymentService: CardPresentPaymentFacade) {
        self.posModel = posModel
        self.cardPresentPaymentService = cardPresentPaymentService
    }

    func connectReaderTapped() {
        Task { @MainActor in
            do {
                let _ = try await cardPresentPaymentService.connectReader(using: .bluetooth)
            } catch {
                DDLogError("🔴 POS reader connection error: \(error)")
            }
        }
    }

    // These three functions could potentially move to posModel and be based on orderStage.
    func onTotalsViewDisappearance() {
        // This is a backup – it's not called until transitions are complete when using the back button.
        // The delay can lead to race conditions with tapping a card.
        // It's likely that the payment will already have been cancelled due to the change of orderStage.
        posModel.cancelCardReaderPreparation()
    }

    func startShowingTotalsView() {
        posModel.observeReaderReconnection()
    }

    func stopShowingTotalsView() {
        posModel.cancelCardReaderPreparation()
    }

    func shouldShowTotalsFields(for paymentState: PointOfSalePaymentState) -> Bool {
        switch paymentState {
        case .idle,
                .acceptingCard,
                .validatingOrder,
                .validatingOrderError,
                .preparingReader:
            return true
        case .processingPayment,
                .paymentError,
                .cardPaymentSuccessful:
            return false
        }
    }
}
