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


struct SilencingAlertsPresenter: CardPresentPaymentAlertsPresenting {
    func present(viewModel: CardPresentPaymentsModalViewModel) {
        // no-op
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
