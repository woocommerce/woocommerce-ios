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

    private var softwareUpdateCancelable: FallibleCancelable? = nil
    private var subscriptions = Set<AnyCancellable>()

    private let configuration: CardPresentPaymentsConfiguration
    private let stores: StoresManager
    private let analytics: Analytics

    init(configuration: CardPresentPaymentsConfiguration,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.configuration = configuration
        self.stores = stores
        self.analytics = analytics

        observeConnectedReaderAndSoftwareUpdate()
    }

    /// Since gateway ID could be fetched asynchronously, this can also be set externally in addition to the initializer.
    func setGatewayID(gatewayID: String?) {
        self.gatewayID = gatewayID
    }

    func setCandidateReader(_ reader: CardReader?) {
        candidateReader = reader
    }

    /// Called when the user taps to cancel card reader software update.
    func softwareUpdateCancelTapped() {
        analytics.track(event: WooAnalyticsEvent.InPersonPayments
            .cardReaderSoftwareUpdateCancelTapped(forGatewayID: gatewayID,
                                                  updateType: .required,
                                                  countryCode: countryCode,
                                                  cardReaderModel: cardReaderModel))
    }

    /// Called after the card reader software update is canceled.
    func softwareUpdateCanceled() {
        analytics.track(event: WooAnalyticsEvent.InPersonPayments
            .cardReaderSoftwareUpdateCanceled(forGatewayID: gatewayID,
                                              updateType: .required,
                                              countryCode: countryCode,
                                              cardReaderModel: cardReaderModel))
    }
}

private extension CardReaderConnectionAnalyticsTracker {
    /// Dispatches actions to the CardPresentPaymentStore so that we can monitor changes to the list of
    /// connected readers and software update states.
    func observeConnectedReaderAndSoftwareUpdate() {
        let action = CardPresentPaymentAction.observeConnectedReaders() { [weak self] readers in
            self?.connectedReader = readers.first
        }
        stores.dispatch(action)

        let softwareUpdateAction = CardPresentPaymentAction.observeCardReaderUpdateState { softwareUpdateEvents in
            softwareUpdateEvents
                .sink { [weak self] state in
                    guard let self = self else { return }

                    switch state {
                    case .started(cancelable: let cancelable):
                        self.softwareUpdateCancelable = cancelable
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
                    case .completed:
                        self.softwareUpdateCancelable = nil
                        self.analytics.track(event: WooAnalyticsEvent.InPersonPayments
                            .cardReaderSoftwareUpdateSuccess(forGatewayID: self.gatewayID,
                                                             updateType: self.updateType,
                                                             countryCode: self.countryCode,
                                                             cardReaderModel: self.cardReaderModel))
                    case .available:
                        self.optionalReaderUpdateAvailable = true
                    case .none:
                        self.optionalReaderUpdateAvailable = false
                    default:
                        break
                    }
                }
                .store(in: &self.subscriptions)
        }
        stores.dispatch(softwareUpdateAction)
    }
}
