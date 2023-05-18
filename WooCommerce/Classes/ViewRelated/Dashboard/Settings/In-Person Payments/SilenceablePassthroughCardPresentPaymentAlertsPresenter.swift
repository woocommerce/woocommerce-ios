import Foundation
import Combine

final class SilenceablePassthroughCardPresentPaymentAlertsPresenter: CardPresentPaymentAlertsPresenting {
    private var alertSubject: CurrentValueSubject<CardPresentPaymentsModalViewModel?, Never> = CurrentValueSubject(nil)
    private var alertsPresenter: CardPresentPaymentAlertsPresenting?

    private var alertSubscription: AnyCancellable? = nil

    func present(viewModel: CardPresentPaymentsModalViewModel) {
        alertSubject.send(viewModel)
    }

    func foundSeveralReaders(readerIDs: [String], connect: @escaping (String) -> Void, cancelSearch: @escaping () -> Void) {
        // no-op – currently this only supports Built In readers, which don't require this
    }

    func updateSeveralReadersList(readerIDs: [String]) {
        // no-op – currently this only supports Built In readers, which don't require this
    }

    func dismiss() {
        alertSubject.send(nil)
        alertsPresenter?.dismiss()
    }

    func startPresentingAlerts(from alertsPresenter: CardPresentPaymentAlertsPresenting) {
        self.alertsPresenter = alertsPresenter
        alertSubscription = alertSubject.share().sink { viewModel in
            DispatchQueue.main.async {
                guard let viewModel = viewModel else {
                    alertsPresenter.dismiss()
                    return
                }
                alertsPresenter.present(viewModel: viewModel)
            }
        }
    }

    func silenceAlerts() {
        alertsPresenter = nil
        alertSubscription?.cancel()
    }
}
