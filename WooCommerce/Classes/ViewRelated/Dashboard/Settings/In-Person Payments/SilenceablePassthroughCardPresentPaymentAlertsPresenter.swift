import Foundation
import Combine

nonisolated final class SilenceablePassthroughCardPresentPaymentAlertsPresenter<AlertPresenter: CardPresentPaymentAlertsPresenting>: CardPresentPaymentAlertsPresenting {
    private var alertSubject: CurrentValueSubject<AlertPresenter.AlertDetails?, Never> = CurrentValueSubject(nil)
    private var alertsPresenter: (any CardPresentPaymentAlertsPresenting<AlertPresenter.AlertDetails>)?

    private var alertSubscription: AnyCancellable? = nil

    @MainActor
    func present(viewModel: AlertPresenter.AlertDetails) {
        alertSubject.send(viewModel)
    }

    @MainActor
    func presentWCSettingsWebView(adminURL: URL, completion: @escaping () -> Void) {
        // TODO: confirm if this is needed
    }

    @MainActor
    func foundSeveralReaders(readerIDs: [String], connect: @escaping (String) -> Void, cancelSearch: @escaping () -> Void) {
        // no-op – currently this only supports Built In readers, which don't require this
    }

    @MainActor
    func updateSeveralReadersList(readerIDs: [String]) {
        // no-op – currently this only supports Built In readers, which don't require this
    }

    @MainActor
    func dismiss() {
        alertSubject.send(nil)
        alertsPresenter?.dismiss()
    }

    func startPresentingAlerts(from alertsPresenter: AlertPresenter) {
        self.alertsPresenter = alertsPresenter
        alertSubscription = alertSubject.share().sink { viewModel in
            DispatchQueue.main.async {
                guard let viewModel else {
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
