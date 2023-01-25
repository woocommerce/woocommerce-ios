import Foundation
import Yosemite
import Combine
#if !targetEnvironment(simulator)
import ProximityReader
#endif

enum CardReaderConnectionResult {
    case connected(CardReader)
    case canceled(WooAnalyticsEvent.InPersonPayments.CancellationSource)
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

    /// Root View Controller
    /// Used for showing onboarding alerts
    private let rootViewController: UIViewController

    /// Onboarding presenter.
    /// Shows messages to help a merchant get correctly set up for card payments, prior to taking a payment.
    ///
    private let onboardingPresenter: CardPresentPaymentsOnboardingPresenting

    /// Stores the connected card reader
    ///
    private var connectedReader: CardReader?

    /// Controller to connect a card reader.
    ///
    private var connectionController: CardReaderConnectionController

    /// Controller to connect a card reader.
    ///
    private var builtInConnectionController: BuiltInCardReaderConnectionController


    private(set) var readerConnection = CurrentValueSubject<CardReaderConnectionResult?, Never>(nil)

    init(siteID: Int64,
         paymentGatewayAccount: PaymentGatewayAccount,
         configuration: CardPresentPaymentsConfiguration,
         rootViewController: UIViewController,
         alertsPresenter: CardPresentPaymentAlertsPresenting,
         onboardingPresenter: CardPresentPaymentsOnboardingPresenting,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.paymentGatewayAccount = paymentGatewayAccount
        self.configuration = configuration
        self.rootViewController = rootViewController
        self.alertsPresenter = alertsPresenter
        self.onboardingPresenter = onboardingPresenter
        self.stores = stores
        self.analytics = analytics
        self.connectedReader = nil
        let analyticsTracker = CardReaderConnectionAnalyticsTracker(configuration: configuration,
                                                                    stores: stores,
                                                                    analytics: analytics)
        self.connectionController = CardReaderConnectionController(
            forSiteID: siteID,
            knownReaderProvider: CardReaderSettingsKnownReaderStorage(),
            alertsPresenter: alertsPresenter,
            alertsProvider: BluetoothReaderConnectionAlertsProvider(),
            configuration: configuration,
            analyticsTracker: analyticsTracker)

        self.builtInConnectionController = BuiltInCardReaderConnectionController(
            forSiteID: siteID,
            alertsPresenter: alertsPresenter,
            alertsProvider: BuiltInReaderConnectionAlertsProvider(),
            configuration: configuration,
            analyticsTracker: analyticsTracker)
    }

    @MainActor
    func start() async {
        configureBackend()
        observeConnectedReaders()
        // If we're already connected to a reader, return it
        if let connectedReader = connectedReader {
            handleConnectionResult(.success(.connected(connectedReader)))
            return
        }

        await onboardingPresenter.showOnboardingIfRequired(from: rootViewController)

        // Ask for a Reader type if supported by device/in country
        guard await localMobileReaderSupported(),
              configuration.supportedReaders.contains(.appleBuiltIn)
        else {
            // Attempt to find a bluetooth reader and connect
            connectionController.searchAndConnect(onCompletion: handleConnectionResult)
            return
        }

        analytics.track(event: .InPersonPayments.cardReaderSelectTypeShown(forGatewayID: paymentGatewayAccount.gatewayID,
                                                                           countryCode: configuration.countryCode))
        alertsPresenter.present(viewModel: CardPresentModalSelectSearchType(
            tapOnIPhoneAction: { [weak self] in
                guard let self = self else { return }
                self.analytics.track(event: .InPersonPayments.cardReaderSelectTypeBuiltInTapped(
                    forGatewayID: self.paymentGatewayAccount.gatewayID,
                    countryCode: self.configuration.countryCode))
                self.builtInConnectionController.searchAndConnect(
                    onCompletion: self.handleConnectionResult)
            },
            bluetoothAction: { [weak self] in
                guard let self = self else { return }
                self.analytics.track(event: .InPersonPayments.cardReaderSelectTypeBluetoothTapped(
                    forGatewayID: self.paymentGatewayAccount.gatewayID,
                    countryCode: self.configuration.countryCode))
                self.connectionController.searchAndConnect(
                    onCompletion: self.handleConnectionResult)
            },
            cancelAction: { [weak self] in
                guard let self = self else { return }
                self.alertsPresenter.dismiss()
                self.handleConnectionResult(.success(.canceled(.selectReaderType)))
            }))
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

    private func handleConnectionResult(_ result: Result<CardReaderConnectionResult, Error>) {
        let connectionResult = result.map { connection in
            if case .connected(let reader) = connection {
                self.connectedReader = reader
            }
            return connection
        }

        switch connectionResult {
        case .success(let unwrapped):
            self.readerConnection.send(unwrapped)
        default:
            alertsPresenter.dismiss()
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
