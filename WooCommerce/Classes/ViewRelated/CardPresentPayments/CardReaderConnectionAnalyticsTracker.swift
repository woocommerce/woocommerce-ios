import Combine
import Foundation
import Yosemite

/// Tracks events during card reader connection flow, including reader connection and optional/required software update events.
final class CardReaderConnectionAnalyticsTracker {
    /// The reader the user has connected.
    private var connectedReader: CardReader?

    /// The reader the user is trying to connect.
    private var candidateReader: CardReader?

    private var updateType: SoftwareUpdateTypeProperty {
        optionalReaderUpdateAvailable ? .optional : .required
    }

    private var cardReaderModel: String {
        (connectedReader ?? candidateReader)?.readerType.model ?? ""
    }

    private var countryCode: String {
        configuration.countryCode
    }

    private(set) var optionalReaderUpdateAvailable: Bool = false

    /// Gateway ID to include in tracks events, which could be set in initialization and/or externally.
    private var gatewayID: String?

    private var softwareUpdateCancelable: AnyCancellable?

    private let configuration: CardPresentPaymentsConfiguration
    private let stores: StoresManager
    private let analytics: Analytics

    init(configuration: CardPresentPaymentsConfiguration,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.configuration = configuration
        self.stores = stores
        self.analytics = analytics

        observeConnectedReader()
    }

    /// Since gateway ID could be fetched asynchronously, this can also be set externally in addition to the initializer.
    func setGatewayID(gatewayID: String?) {
        self.gatewayID = gatewayID
    }

    func setCandidateReader(_ reader: CardReader?) {
        candidateReader = reader
        if reader != nil {
            observeSoftwareUpdateState()
        } else {
            softwareUpdateCancelable?.cancel()
        }
    }

    /// Called when the user taps to update card reader software when it is available.
    func cardReaderSoftwareUpdateTapped() {
        analytics.track(event: WooAnalyticsEvent.InPersonPayments
            .cardReaderSoftwareUpdateTapped(forGatewayID: gatewayID,
                                            updateType: updateType,
                                            countryCode: configuration.countryCode,
                                            cardReaderModel: cardReaderModel))
    }

    /// Called when the user taps to cancel card reader software update.
    func cardReaderSoftwareUpdateCancelTapped() {
        analytics.track(event: WooAnalyticsEvent.InPersonPayments
            .cardReaderSoftwareUpdateCancelTapped(forGatewayID: gatewayID,
                                                  updateType: .required,
                                                  countryCode: countryCode,
                                                  cardReaderModel: cardReaderModel))
    }

    /// Called after the card reader software update is canceled.
    func cardReaderSoftwareUpdateCanceled() {
        softwareUpdateCancelable?.cancel()
        analytics.track(event: WooAnalyticsEvent.InPersonPayments
            .cardReaderSoftwareUpdateCanceled(forGatewayID: gatewayID,
                                              updateType: .required,
                                              countryCode: countryCode,
                                              cardReaderModel: cardReaderModel))
        completeCardReaderUpdate(success: false)
    }

    /// Called when the user taps to disconnect card reader.
    func cardReaderDisconnectTapped() {
        analytics.track(event: WooAnalyticsEvent.InPersonPayments
            .cardReaderDisconnectTapped(forGatewayID: gatewayID,
                                        countryCode: configuration.countryCode,
                                        cardReaderModel: cardReaderModel))
    }
}

private extension CardReaderConnectionAnalyticsTracker {
    func observeConnectedReader() {
        let action = CardPresentPaymentAction.observeConnectedReaders() { [weak self] readers in
            self?.connectedReader = readers.first
        }
        stores.dispatch(action)
    }

    func observeSoftwareUpdateState() {
        let softwareUpdateAction = CardPresentPaymentAction.observeCardReaderUpdateState { [weak self] softwareUpdateEvents in
            guard let self = self else { return }
            self.softwareUpdateCancelable = softwareUpdateEvents
                .sink { [weak self] state in
                    guard let self = self else { return }
                    switch state {
                    case .started:
                        self.analytics.track(
                            event: WooAnalyticsEvent.InPersonPayments
                                .cardReaderSoftwareUpdateStarted(forGatewayID: self.gatewayID,
                                                                 updateType: self.updateType,
                                                                 countryCode: self.countryCode,
                                                                 cardReaderModel: self.cardReaderModel)
                        )
                    case .failed(error: let error):
                        if case CardReaderServiceError.softwareUpdate(underlyingError: let underlyingError, batteryLevel: _) = error,
                           underlyingError == .readerSoftwareUpdateFailedInterrupted {
                            // Update was cancelled, don't treat this as an error
                            break
                        }
                        self.analytics.track(event: WooAnalyticsEvent.InPersonPayments
                            .cardReaderSoftwareUpdateFailed(forGatewayID: self.gatewayID,
                                                            updateType: self.updateType,
                                                            error: error,
                                                            countryCode: self.countryCode,
                                                            cardReaderModel: self.cardReaderModel))
                        self.completeCardReaderUpdate(success: false)
                    case .completed:
                        self.softwareUpdateCancelable?.cancel()
                        self.analytics.track(event: WooAnalyticsEvent.InPersonPayments
                            .cardReaderSoftwareUpdateSuccess(forGatewayID: self.gatewayID,
                                                             updateType: self.updateType,
                                                             countryCode: self.countryCode,
                                                             cardReaderModel: self.cardReaderModel))
                        self.completeCardReaderUpdate(success: true)
                    case .available:
                        self.optionalReaderUpdateAvailable = true
                    case .none:
                        self.optionalReaderUpdateAvailable = false
                    default:
                        break
                    }
                }
        }
        stores.dispatch(softwareUpdateAction)
    }

    func completeCardReaderUpdate(success: Bool) {
        // Avoids a failed mandatory reader update being shown as optional
        optionalReaderUpdateAvailable = optionalReaderUpdateAvailable && !success
    }
}
