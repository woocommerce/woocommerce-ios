import Foundation
import Yosemite
import Combine
#if !targetEnvironment(simulator)
import ProximityReader
#endif

enum CardReaderConnectionResult {
    case connected(CardReader)
    case canceled
}

final class CardPresentPaymentPreflightController {
    /// Store's ID.
    ///
    private let siteID: Int64

    /// Payment Gateway Account to use.
    ///
    private let paymentGatewayAccount: PaymentGatewayAccount

    /// IPP Configuration.
    ///
    private let configuration: CardPresentPaymentsConfiguration

    /// Alerts presenter to send alert view models
    ///
    private var alertsPresenter: CardPresentPaymentAlertsPresenting

    /// Stores manager.
    ///
    private let stores: StoresManager

    /// Analytics manager.
    ///
    private let analytics: Analytics

    /// Stores the connected card reader
    private var connectedReader: CardReader?


    /// Controller to connect a card reader.
    ///
    private var connectionController: CardReaderConnectionController

    /// Controller to connect a card reader.
    ///
    private var builtInConnectionController: CardReaderConnectionController


    private(set) var readerConnection = CurrentValueSubject<CardReaderConnectionResult?, Never>(nil)

    init(siteID: Int64,
         paymentGatewayAccount: PaymentGatewayAccount,
         configuration: CardPresentPaymentsConfiguration,
         alertsPresenter: CardPresentPaymentAlertsPresenting,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.paymentGatewayAccount = paymentGatewayAccount
        self.configuration = configuration
        self.alertsPresenter = alertsPresenter
        self.stores = stores
        self.analytics = analytics
        self.connectedReader = nil
        let analyticsTracker = CardReaderConnectionAnalyticsTracker(configuration: configuration,
                                                                    stores: stores,
                                                                    analytics: analytics)
        // TODO: Replace this with a refactored (New)LegacyCardReaderConnectionController
        self.connectionController = CardReaderConnectionController(
            forSiteID: siteID,
            discoveryMethod: .bluetoothProximity,
            knownReaderProvider: CardReaderSettingsKnownReaderStorage(),
            alertsPresenter: alertsPresenter,
            configuration: configuration,
            analyticsTracker: analyticsTracker)

        self.builtInConnectionController = CardReaderConnectionController(
            forSiteID: siteID,
            discoveryMethod: .localMobile,
            knownReaderProvider: CardReaderSettingsKnownReaderStorage(),
            alertsPresenter: alertsPresenter,
            configuration: configuration,
            analyticsTracker: analyticsTracker)
    }

    func start() {
        configureBackend()
        observeConnectedReaders()
        // If we're already connected to a reader, return it
        if let connectedReader = connectedReader {
            readerConnection.send(CardReaderConnectionResult.connected(connectedReader))
        }

        // TODO: Run onboarding if needed

        // Ask for a Reader type if supported by device/in country
        guard localMobileReaderSupported(),
              configuration.supportedReaders.contains(.appleBuiltIn)
        else {
            // Attempt to find a bluetooth reader and connect
            connectionController.searchAndConnect(onCompletion: handleConnectionResult)
            return
        }

        alertsPresenter.present(viewModel: CardPresentModalSelectSearchType(
            tapOnIPhoneAction: { [weak self] in
                guard let self = self else { return }
                self.builtInConnectionController.searchAndConnect(
                    onCompletion: self.handleConnectionResult)
            },
            bluetoothAction: { [weak self] in
                guard let self = self else { return }
                self.connectionController.searchAndConnect(
                    onCompletion: self.handleConnectionResult)
            }))
    }

    private func localMobileReaderSupported() -> Bool {
        #if !targetEnvironment(simulator)
        if #available(iOS 15.4, *) {
            return PaymentCardReader.isSupported
        } else {
            return false
        }
        #endif
        return true
    }

    private func handleConnectionResult(_ result: Result<CardReaderConnectionController.ConnectionResult, Error>) {
        let connectionResult = result.map { connection in
            switch connection {
            case .connected:
                // TODO: pass the reader from the (New)CardReaderConnectionController
                guard let connectedReader = self.connectedReader else { return CardReaderConnectionResult.canceled }
                return CardReaderConnectionResult.connected(connectedReader)
            case .canceled:
                return CardReaderConnectionResult.canceled
            }
        }

        switch connectionResult {
        case .success(let unwrapped):
            self.readerConnection.send(unwrapped)
        default:
            break
        }
    }

    /// Configure the CardPresentPaymentStore to use the appropriate backend
    ///
    private func configureBackend() {
        let setAccount = CardPresentPaymentAction.use(paymentGatewayAccount: paymentGatewayAccount)
        stores.dispatch(setAccount)
    }

    private func observeConnectedReaders() {
        let action = CardPresentPaymentAction.observeConnectedReaders() { [weak self] readers in
            self?.connectedReader = readers.first
        }
        stores.dispatch(action)
    }
}
