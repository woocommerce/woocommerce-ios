import Foundation
@testable import WooCommerce

final class MockCardPresentPaymentAlertsPresenter: CardPresentPaymentAlertsPresenting {
    var spyPresentedAlertViewModels: [CardPresentPaymentsModalViewModel] = []
    func present(viewModel: CardPresentPaymentsModalViewModel) {
        spyPresentedAlertViewModels.append(viewModel)
    }

    func foundSeveralReaders(readerIDs: [String], connect: @escaping (String) -> Void, cancelSearch: @escaping () -> Void) {
        // no-op
    }

    func updateSeveralReadersList(readerIDs: [String]) {
        // no-op
    }

    func dismiss() {
        // no-op
    }
}
