import Foundation
import Yosemite
import Combine

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

        // TODO: Ask for a Reader type if supported by device

        // Attempt to find a reader and connect
        connectionController.searchAndConnect { result in
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
