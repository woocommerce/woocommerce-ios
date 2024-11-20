import SwiftUI
import Combine
import protocol Yosemite.POSItem

final class TotalsViewModel: ObservableObject, TotalsViewModelProtocol {

    @ObservedObject var posModel: PointOfSaleAggregateModel

    init(posModel: PointOfSaleAggregateModel) {
        self.posModel = posModel
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
