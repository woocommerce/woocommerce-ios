import Foundation
import Yosemite

protocol BuiltInCardReaderConnectionControllerBuilding<AlertProvider, AlertPresenter> {
    associatedtype AlertProvider
    associatedtype AlertPresenter
    func createConnectionController(forSiteID: Int64,
                                    alertPresenter: AlertPresenter,
                                    configuration: CardPresentPaymentsConfiguration,
                                    analyticsTracker: CardReaderConnectionAnalyticsTracker,
                                    allowTermsOfServiceAcceptance: Bool) -> BuiltInCardReaderConnectionControlling
}

final class BuiltInCardReaderConnectionControllerFactory<AlertProvider: CardReaderConnectionAlertsProviding,
                                                         AlertPresenter: CardPresentPaymentAlertsPresenting>:
                                                            BuiltInCardReaderConnectionControllerBuilding
where AlertPresenter.AlertDetails == AlertProvider.AlertDetails {
    private let alertProvider: AlertProvider

    init(alertProvider: AlertProvider) {
        self.alertProvider = alertProvider
    }

    func createConnectionController(forSiteID siteID: Int64,
                                    alertPresenter: AlertPresenter,
                                    configuration: CardPresentPaymentsConfiguration,
                                    analyticsTracker: CardReaderConnectionAnalyticsTracker,
                                    allowTermsOfServiceAcceptance: Bool) -> BuiltInCardReaderConnectionControlling {
        BuiltInCardReaderConnectionController(
            forSiteID: siteID,
            alertsPresenter: alertPresenter,
            alertsProvider: alertProvider,
            configuration: configuration,
            analyticsTracker: analyticsTracker,
            allowTermsOfServiceAcceptance: allowTermsOfServiceAcceptance)
    }
}

final class TapToPayReconnectionController<AlertProvider: CardReaderConnectionAlertsProviding,
                                            AlertPresenter: CardPresentPaymentAlertsPresenting>
where AlertProvider.AlertDetails == AlertPresenter.AlertDetails {

    private let stores: StoresManager

    private var configuration: CardPresentPaymentsConfiguration {
        CardPresentConfigurationLoader().configuration
    }

    private var siteID: Int64 {
        stores.sessionManager.defaultStoreID ?? 0
    }

    private let onboardingCache: CardPresentPaymentOnboardingStateCache

    private let connectionControllerFactory: any BuiltInCardReaderConnectionControllerBuilding<
        AlertProvider, SilenceablePassthroughCardPresentPaymentAlertsPresenter<AlertPresenter>>

    private var connectionController: BuiltInCardReaderConnectionControlling? = nil

    private var silencingAlertsPresenter: SilenceablePassthroughCardPresentPaymentAlertsPresenter<AlertPresenter>

    private var adoptedConnectionCompletionHandler: ((Result<CardReaderConnectionResult, Error>) -> Void)? = nil

    init(stores: StoresManager = ServiceLocator.stores,
         connectionControllerFactory: any BuiltInCardReaderConnectionControllerBuilding<
         AlertProvider, SilenceablePassthroughCardPresentPaymentAlertsPresenter<AlertPresenter>>,
         onboardingCache: CardPresentPaymentOnboardingStateCache = .shared) {
        self.stores = stores
        self.connectionControllerFactory = connectionControllerFactory
        self.silencingAlertsPresenter = SilenceablePassthroughCardPresentPaymentAlertsPresenter()
        self.onboardingCache = onboardingCache
    }

    private(set) var isReconnecting: Bool = false

    /// Reconnects to the built in Tap to Pay on iPhone reader if:
    /// - it's supported,
    /// - it has been used on this device and site before, and
    /// - there's no other reader connected
    /// - In Person Payments onboarding is cached as `.completed`
    /// - Parameters:
    ///   - supportDeterminer: Overridable for testing purposes

    func reconnectIfNeeded(supportDeterminer: CardReaderSupportDetermining? = nil) {
        isReconnecting = true
        let supportDeterminer = supportDeterminer ?? CardReaderSupportDeterminer(siteID: siteID)
        Task { @MainActor in
            guard supportDeterminer.locationIsAuthorized,
                  supportDeterminer.siteSupportsLocalMobileReader(),
                  await supportDeterminer.deviceSupportsLocalMobileReader(),
                  await supportDeterminer.hasPreviousTapToPayUsage(),
                  await supportDeterminer.connectedReader() == nil,
                  case .completed = onboardingCache.value else {
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
    func showAlertsForReconnection(from alertsPresenter: AlertPresenter,
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
        let connectionController = builtInConnectionControllerForReconnection()

        connectionController.searchAndConnect(onCompletion: { [weak self] result in
            guard let self = self else { return }
            self.adoptedConnectionCompletionHandler?(result)
            self.reset()
        })
    }

    func builtInConnectionControllerForReconnection() -> BuiltInCardReaderConnectionControlling {
        // If we already have a connection controller, there may be a reconnection in progress.
        // Starting again now would result in an SDK failure, and lose our original reference to the controller.
        // Reusing the connection controller will only cause a restart if the controller is idle,
        // and will update the completion to this object's completion.
        if let connectionController {
            return connectionController
        }

        let connectionController = connectionControllerFactory.createConnectionController(
            forSiteID: siteID,
            alertPresenter: silencingAlertsPresenter,
            configuration: configuration,
            analyticsTracker: CardReaderConnectionAnalyticsTracker(configuration: configuration,
                                                                   siteID: siteID,
                                                                   connectionType: .automaticReconnection),
            allowTermsOfServiceAcceptance: false)
        self.connectionController = connectionController

        return connectionController
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
