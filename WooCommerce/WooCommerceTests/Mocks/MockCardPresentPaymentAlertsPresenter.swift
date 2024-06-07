import Foundation
@testable import WooCommerce

final class MockCardPresentPaymentAlertsPresenter: CardPresentPaymentAlertsPresenting {
    var mode: MockCardPresentPaymentAlertsPresenterMode = .doNothing

    init(mode: MockCardPresentPaymentAlertsPresenterMode = .doNothing) {
        self.mode = mode
    }

    var onPresentCalled: ((CardPresentPaymentsModalViewModel) -> Void)? = nil
    var spyPresentedAlertViewModels: [CardPresentPaymentsModalViewModel] = []
    func present(viewModel: CardPresentPaymentsModalViewModel) {
        spyPresentedAlertViewModels.append(viewModel)
        onPresentCalled?(viewModel)
    }

    func presentWCSettingsWebView(adminURL: URL, completion: @escaping () -> Void) {
        // no-op
    }

    func foundSeveralReaders(readerIDs: [String],
                             connect: @escaping (String) -> Void,
                             cancelSearch: @escaping () -> Void) {
        let readerID = readerIDs.first ?? ""
        if mode == .connectFirstFound {
            connect(readerID)
        }

        if mode == .cancelFoundSeveral {
            cancelSearch()
        }
    }

    func updateSeveralReadersList(readerIDs: [String]) {
        // no-op
    }

    func dismiss() {
        // no-op
    }
}

enum MockCardPresentPaymentAlertsPresenterMode {
    case doNothing
    case connectFirstFound
    case cancelFoundSeveral
}
