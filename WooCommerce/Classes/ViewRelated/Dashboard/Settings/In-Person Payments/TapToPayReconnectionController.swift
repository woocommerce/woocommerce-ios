import Foundation
import Yosemite

final class TapToPayReconnectionController {

    private let stores: StoresManager
    private let connectionController: BuiltInCardReaderConnectionController
    private var configuration: CardPresentPaymentsConfiguration {
        CardPresentConfigurationLoader().configuration
    }
    private let silencingAlertsPresenter: SilencingAlertsPresenter

    private var siteID: Int64 {
        stores.sessionManager.defaultStoreID ?? 0
    }

    private(set) var isReconnecting: Bool = false

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
        let silencingAlertsPresenter = SilencingAlertsPresenter()
        self.silencingAlertsPresenter = silencingAlertsPresenter
        #warning("This needs to be recreated whenever we switch stores, or the configuration could be out of date")
        self.connectionController = BuiltInCardReaderConnectionController(
            forSiteID: ServiceLocator.stores.sessionManager.defaultStoreID ?? 0,
            alertsPresenter: silencingAlertsPresenter,
            alertsProvider: BuiltInReaderConnectionAlertsProvider(),
            configuration: CardPresentConfigurationLoader().configuration,
            analyticsTracker: CardReaderConnectionAnalyticsTracker(configuration: CardPresentConfigurationLoader().configuration),
            allowTermsOfServiceAcceptance: false)
    }

    func reconnectIfNeeded() async {
        isReconnecting = true
        guard configuration.supportedReaders.contains(.appleBuiltIn),
            await localMobileReaderSupported(),
            await hasPreviousTapToPayUsage(),
            await connectedReader() == nil else {
            silencingAlertsPresenter.silenceAlerts()
            adoptedConnectionCompletionHandler = nil
            connectionController.allowTermsOfServiceAcceptance = false
            isReconnecting = false
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
        connectionController.searchAndConnect(onCompletion: { [weak self] result in
            DDLogInfo("💸 Reconnected to Tap to Pay \(result)")
            self?.adoptedConnectionCompletionHandler?(result)
            self?.silencingAlertsPresenter.silenceAlerts()
            self?.adoptedConnectionCompletionHandler = nil
            self?.connectionController.allowTermsOfServiceAcceptance = false
            self?.isReconnecting = false
        })
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

    private var adoptedConnectionCompletionHandler: ((Result<CardReaderConnectionResult, Error>) -> Void)? = nil

    func showAlertsForReconnection(from alertsPresenter: CardPresentPaymentAlertsPresenting,
                                   onCompletion: @escaping (Result<CardReaderConnectionResult, Error>) -> Void) {
        connectionController.allowTermsOfServiceAcceptance = true
        adoptedConnectionCompletionHandler = onCompletion
        silencingAlertsPresenter.startPresentingAlerts(from: alertsPresenter)
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
