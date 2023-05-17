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

    private var silencingAlertsPresenter: SilenceablePassthroughCardPresentPaymentAlertsPresenter

    private var adoptedConnectionCompletionHandler: ((Result<CardReaderConnectionResult, Error>) -> Void)? = nil

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
        self.silencingAlertsPresenter = SilenceablePassthroughCardPresentPaymentAlertsPresenter()
    }

    private(set) var isReconnecting: Bool = false

    /// Reconnects to the built in Tap to Pay on iPhone reader if:
    /// - it's supported,
    /// - it has been used on this device and site before, and
    /// - there's no other connected readers.
    func reconnectIfNeeded() {
        isReconnecting = true
        let supportDeterminer = CardReaderSupportDeterminer(siteID: siteID)
        Task { @MainActor in
            guard supportDeterminer.siteSupportsLocalMobileReader(),
                  await supportDeterminer.deviceSupportsLocalMobileReader(),
                  await supportDeterminer.hasPreviousTapToPayUsage(),
                  await supportDeterminer.connectedReader() == nil else {
                reset()
                return
            }

            reconnectToTapToPayReader()
        }
    }

    /// Allows another connection process to adopt an in-progress background automatic Tap to Pay reconnection.
    /// This is because connections are generally not cancellable, so we need to show their progress.
    /// If a different reader type was selected, disconnecting and reconnecting in the completion handler is appropriate.
    /// - Parameters:
    ///   - alertsPresenter: The alerts presenter which can show the connection alerts.
    ///   It will be immediately called with the most recent alert
    ///   - onCompletion: A completion handler for the automatic reconnection, with success or an error.
    func showAlertsForReconnection(from alertsPresenter: CardPresentPaymentAlertsPresenting,
                                   onCompletion: @escaping (Result<CardReaderConnectionResult, Error>) -> Void) {
        guard isReconnecting else {
            return onCompletion(.failure(TapToPayReconnectionError.noReconnectionInProgress))
        }
        adoptedConnectionCompletionHandler = onCompletion
        silencingAlertsPresenter.startPresentingAlerts(from: alertsPresenter)
    }
}

private extension TapToPayReconnectionController {
    func reconnectToTapToPayReader() {
        // If we already have a connection controller, there's a reconnection in progress.
        // Starting again now would result in an SDK failure, and lose our original reference to the controller.
        guard connectionController == nil else {
            return
        }

        createConnectionController()

        connectionController?.searchAndConnect(onCompletion: { [weak self] result in
            guard let self = self else { return }
            DDLogInfo("💸 Reconnected to Tap to Pay \(result)")
            self.adoptedConnectionCompletionHandler?(result)
            self.reset()
        })
    }

    func createConnectionController() {
        connectionController = BuiltInCardReaderConnectionController(
            forSiteID: siteID,
            alertsPresenter: silencingAlertsPresenter,
            alertsProvider: BuiltInReaderConnectionAlertsProvider(),
            configuration: configuration,
            analyticsTracker: CardReaderConnectionAnalyticsTracker(configuration: configuration))
    }

    func reset() {
        silencingAlertsPresenter.silenceAlerts()
        adoptedConnectionCompletionHandler = nil
        connectionController = nil
        isReconnecting = false
    }
}

enum TapToPayReconnectionError: Error {
    case noReconnectionInProgress
}
