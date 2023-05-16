import Foundation
import Yosemite

final class TapToPayReconnectionController {

    private let stores: StoresManager

    private var configuration: CardPresentPaymentsConfiguration {
        CardPresentConfigurationLoader().configuration
    }

    private var siteID: Int64 {
        stores.sessionManager.defaultStoreID ?? 0
    }

    private var connectionController: BuiltInCardReaderConnectionController? = nil

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    /// Reconnects to the built in Tap to Pay on iPhone reader if:
    /// - it's supported,
    /// - it has been used on this device and site before, and
    /// - there's no other connected readers.
    func reconnectIfNeeded() {
        let supportDeterminer = CardReaderSupportDeterminer(siteID: siteID)
        Task { @MainActor in
            guard supportDeterminer.siteSupportsLocalMobileReader(),
                  await supportDeterminer.deviceSupportsLocalMobileReader(),
                  await supportDeterminer.hasPreviousTapToPayUsage(),
                  await supportDeterminer.connectedReader() == nil else {
                return
            }

            reconnectToTapToPayReader()
        }
    }

    private func reconnectToTapToPayReader() {
        // If we already have a connection controller, there's a reconnection in progress.
        // Starting again now would result in an SDK failure, and lose our original reference to the controller.
        guard connectionController == nil else {
            return
        }
        connectionController = BuiltInCardReaderConnectionController(forSiteID: siteID,
                                                                     alertsPresenter: SilencingAlertsPresenter(),
                                                                     alertsProvider: BuiltInReaderConnectionAlertsProvider(),
                                                                     configuration: configuration,
                                                                     analyticsTracker: CardReaderConnectionAnalyticsTracker(configuration: configuration))
        connectionController?.searchAndConnect(onCompletion: { [weak self] result in
            guard let self = self else { return }
            DDLogInfo("💸 Reconnected to Tap to Pay \(result)")
            self.connectionController = nil
        })
    }
}

import Combine
final class SilencingAlertsPresenter: CardPresentPaymentAlertsPresenting {
    private var alertSubject: CurrentValueSubject<CardPresentPaymentsModalViewModel?, Never> = CurrentValueSubject(nil)
    private var alertsPresenter: CardPresentPaymentAlertsPresenting?

    private var alertSubscription: AnyCancellable? = nil

    func present(viewModel: CardPresentPaymentsModalViewModel) {
        alertSubject.send(viewModel)
    }

    func foundSeveralReaders(readerIDs: [String], connect: @escaping (String) -> Void, cancelSearch: @escaping () -> Void) {
        // no-op
    }

    func updateSeveralReadersList(readerIDs: [String]) {
        // no-op
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
