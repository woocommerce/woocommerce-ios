import Foundation
import Yosemite

final class TapToPayReconnectionController {

    private let stores: StoresManager
    private let connectionController: BuiltInCardReaderConnectionController
    private let configuration: CardPresentPaymentsConfiguration

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
        self.configuration = CardPresentConfigurationLoader().configuration
        self.connectionController = BuiltInCardReaderConnectionController(forSiteID: ServiceLocator.stores.sessionManager.defaultStoreID ?? 0,
                                          alertsPresenter: SilencingAlertsPresenter(),
                                          alertsProvider: BuiltInReaderConnectionAlertsProvider(),
                                          configuration: CardPresentConfigurationLoader().configuration,
                                          analyticsTracker: CardReaderConnectionAnalyticsTracker(configuration: CardPresentConfigurationLoader().configuration))
    }

    func reconnectIfNeeded() async {
        guard configuration.supportedReaders.contains(.appleBuiltIn),
            await localMobileReaderSupported(),
            await hasPreviousTapToPayUsage(),
            await connectedReader() == nil else {
            return
        }
        // since we've had a TTP transaction on this phone before, reconnect
        await reconnectToTapToPayReader()
    }

    @MainActor
    private func connectedReader() async -> CardReader? {
        await withCheckedContinuation { continuation in
            let action = CardPresentPaymentAction.publishCardReaderConnections { connectionPublisher in
                _ = connectionPublisher.sink { readers in
                    continuation.resume(returning: readers.first)
                }
            }
            self.stores.dispatch(action)
        }
    }

    @MainActor
    private func hasPreviousTapToPayUsage() async -> Bool {
        await withCheckedContinuation { continuation in
            let action = AppSettingsAction.loadFirstInPersonPaymentsTransactionDate(siteID: siteID,
                                                                                    cardReaderType: .appleBuiltIn) { date in
                continuation.resume(returning: date != nil)
            }

            self.stores.dispatch(action)
        }
    }

    @MainActor
    private func reconnectToTapToPayReader() {
        connectionController.searchAndConnect(onCompletion: { result in
            DDLogInfo("💸 Reconnected to Tap to Pay \(result)")
        })
    }

    private var siteID: Int64 {
        stores.sessionManager.defaultStoreID ?? 0
    }

    @MainActor
    private func localMobileReaderSupported() async -> Bool {
        await withCheckedContinuation { continuation in
            let action = CardPresentPaymentAction.checkDeviceSupport(siteID: siteID,
                                                                     cardReaderType: .appleBuiltIn,
                                                                     discoveryMethod: .localMobile) { result in
                continuation.resume(returning: result)
            }
            stores.dispatch(action)
        }
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
