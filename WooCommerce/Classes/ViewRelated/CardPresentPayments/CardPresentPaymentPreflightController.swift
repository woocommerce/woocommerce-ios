import Foundation
import Yosemite
import Combine
import protocol WooFoundation.Analytics

enum CardReaderPreflightResult {
    case completed(CardReader, PaymentGatewayAccount)
    case canceled(WooAnalyticsEvent.InPersonPayments.CancellationSource, PaymentGatewayAccount)
}

enum CardReaderConnectionResult {
    case connected(CardReader)
    case canceled(WooAnalyticsEvent.InPersonPayments.CancellationSource)
}

protocol CardPresentPaymentPreflightControllerProtocol {
    func start(discoveryMethod: CardReaderDiscoveryMethod?) async

    var readerConnection: AnyPublisher<CardReaderPreflightResult?, Never> { get }
}

final class CardPresentPaymentPreflightController<TapToPayAlertProvider: CardReaderConnectionAlertsProviding,
                                                  BluetoothAlertProvider: BluetoothReaderConnnectionAlertsProviding,
                                                  AlertPresenter: CardPresentPaymentAlertsPresenting>: CardPresentPaymentPreflightControllerProtocol
where TapToPayAlertProvider.AlertDetails == AlertPresenter.AlertDetails,
      BluetoothAlertProvider.AlertDetails == AlertPresenter.AlertDetails {
    /// Store's ID.
    ///
    private let siteID: Int64

    private var discoveryMethod: CardReaderDiscoveryMethod? = nil

    /// IPP Configuration.
    ///
    private let configuration: CardPresentPaymentsConfiguration

    /// Alerts presenter to send alert view models
    ///
    private var alertsPresenter: AlertPresenter

    /// Stores manager.
    ///
    private let stores: StoresManager

    /// Analytics manager.
    ///
    private let analytics: Analytics

    /// Root View Controller
    /// Used for showing onboarding alerts
    private let rootViewController: ViewControllerPresenting

    /// Onboarding presenter.
    /// Shows messages to help a merchant get correctly set up for card payments, prior to taking a payment.
    ///
    private let onboardingPresenter: CardPresentPaymentsOnboardingPresenting

    /// Stores the connected card reader
    ///
    private var connectedReader: CardReader?

    /// Controller to connect a card reader.
    ///
    private var connectionController: CardReaderConnectionController<BluetoothAlertProvider, AlertPresenter>

    /// Controller to connect a card reader.
    ///
    private var builtInConnectionController: BuiltInCardReaderConnectionController<TapToPayAlertProvider, AlertPresenter>

    private var tapToPayAlertProvider: TapToPayAlertProvider

    private var readerConnectionSubject = CurrentValueSubject<CardReaderPreflightResult?, Never>(nil)

    var readerConnection: AnyPublisher<CardReaderPreflightResult?, Never> {
        readerConnectionSubject.eraseToAnyPublisher()
    }

    private let analyticsTracker: CardReaderConnectionAnalyticsTracker

    private let supportDeterminer: CardReaderSupportDeterminer

    private let tapToPayReconnectionController: TapToPayReconnectionController<TapToPayAlertProvider, AlertPresenter>

    init(siteID: Int64,
         configuration: CardPresentPaymentsConfiguration,
         rootViewController: ViewControllerPresenting,
         alertsPresenter: AlertPresenter,
         onboardingPresenter: CardPresentPaymentsOnboardingPresenting,
         tapToPayAlertProvider: TapToPayAlertProvider,
         externalReaderConnectionController: CardReaderConnectionController<BluetoothAlertProvider, AlertPresenter>,
         tapToPayConnectionController: BuiltInCardReaderConnectionController<TapToPayAlertProvider, AlertPresenter>,
         tapToPayReconnectionController: TapToPayReconnectionController<TapToPayAlertProvider, AlertPresenter>,
         analyticsTracker: CardReaderConnectionAnalyticsTracker,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.configuration = configuration
        self.rootViewController = rootViewController
        self.alertsPresenter = alertsPresenter
        self.onboardingPresenter = onboardingPresenter
        self.tapToPayReconnectionController = tapToPayReconnectionController
        self.stores = stores
        self.analytics = analytics
        self.connectedReader = nil
        self.analyticsTracker = analyticsTracker
        self.tapToPayAlertProvider = tapToPayAlertProvider
        self.connectionController = externalReaderConnectionController
        self.builtInConnectionController = tapToPayConnectionController

        self.supportDeterminer = CardReaderSupportDeterminer(siteID: siteID, configuration: configuration, stores: stores)
    }

    @MainActor
    func start(discoveryMethod: CardReaderDiscoveryMethod?) async {
        self.discoveryMethod = discoveryMethod
        observeConnectedReaders()
        await checkForConnectedReader()
    }

    @MainActor
    private func checkForConnectedReader() async {
        if let connectedReader = connectedReader,
           let paymentGatewayAccount = await selectedPaymentGateway() {
            // The reader was already connected when the analyticsTracker was created,
            //`so we need to pass it along for properties to be correct
            analyticsTracker.setCandidateReader(connectedReader)
            if connectedReader.discoveryMethod == discoveryMethod {
                // If we're already connected to a reader of the correct type, return it
                return handleConnectionResult(.success(.connected(connectedReader)), paymentGatewayAccount: paymentGatewayAccount)
            } else {
                // If it's the wrong type, disconnect it automatically and check onboarding
                do {
                    try await automaticallyDisconnectFromReader()
                    analyticsTracker.automaticallyDisconnectedFromReader()
                    checkOnboarding()
                } catch {
                    return handlePreflightFailure(
                        error: CardPresentPaymentPreflightError.failedToAutomaticallyDisconnect(reader: connectedReader))
                }
            }
        } else {
            // If we're not connected, check onboarding
            checkOnboarding()
        }
    }

    @MainActor
    private func automaticallyDisconnectFromReader() async throws {
        try await withCheckedThrowingContinuation { continuation in
            let action = CardPresentPaymentAction.disconnect { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }
    }

    private func checkOnboarding() {
        // Can't currently make this async without leaking the continuation.
        onboardingPresenter.showOnboardingIfRequired(from: rootViewController) { [weak self] in
            guard let self = self else { return }
            Task {
                await self.continuePreflight()
            }
        }
    }

    @MainActor
    private func continuePreflight() async {
        // Once onboarding is complete, a Payment Gateway will have been chosen
        guard let paymentGatewayAccount = await selectedPaymentGateway() else {
            DDLogError("⛔️ Cannot proceed with reader connection, no Payment Gateway found")
            return handlePreflightFailure(error: CardPresentPaymentPreflightError.paymentGatewayAccountNotFound)
        }

        await startReaderConnection(using: paymentGatewayAccount)
    }


    private func startReaderConnection(using paymentGatewayAccount: PaymentGatewayAccount) async {
        guard !tapToPayReconnectionController.isReconnecting else {
            return adoptReconnection(using: paymentGatewayAccount)
        }
        let localMobileReaderSupported = await supportDeterminer.deviceSupportsLocalMobileReader() && supportDeterminer.siteSupportsLocalMobileReader()

        switch (discoveryMethod, localMobileReaderSupported) {
        case (.none, true):
            await promptForReaderTypeSelection(paymentGatewayAccount: paymentGatewayAccount)
        case (.bluetoothScan, _),
            (.none, false):
            connectionController.searchAndConnect(onCompletion: { [weak self] result in
                self?.handleConnectionResult(result, paymentGatewayAccount: paymentGatewayAccount)
            })
        case (.localMobile, true):
            builtInConnectionController.searchAndConnect(onCompletion: { [weak self] result in
                self?.handleConnectionResult(result, paymentGatewayAccount: paymentGatewayAccount)
            })
        case (.localMobile, false):
            handlePreflightFailure(error: CardPresentPaymentPreflightError.localMobileReaderNotSupported)
        }
    }

    private func adoptReconnection(using paymentGatewayAccount: PaymentGatewayAccount) {
        tapToPayReconnectionController.showAlertsForReconnection(from: alertsPresenter) { [weak self] result in
            guard let self = self else { return }
            switch self.discoveryMethod {
            case .bluetoothScan:
                Task { [weak self] in
                    try await self?.automaticallyDisconnectFromReader()
                    await self?.startReaderConnection(using: paymentGatewayAccount)
                }
            case .localMobile, .none:
                self.handleConnectionResult(result, paymentGatewayAccount: paymentGatewayAccount)
            }
        }
    }

    @MainActor
    private func promptForReaderTypeSelection(paymentGatewayAccount: PaymentGatewayAccount) {
        analytics.track(event: .InPersonPayments.cardReaderSelectTypeShown(forGatewayID: paymentGatewayAccount.gatewayID,
                                                                           countryCode: configuration.countryCode))
        alertsPresenter.present(viewModel: tapToPayAlertProvider.selectSearchType(tapToPay: {[weak self] in
            guard let self = self else { return }
            self.analytics.track(event: .InPersonPayments.cardReaderSelectTypeBuiltInTapped(
                forGatewayID: paymentGatewayAccount.gatewayID,
                countryCode: self.configuration.countryCode))
            self.builtInConnectionController.searchAndConnect(onCompletion: { [weak self] result in
                self?.handleConnectionResult(result, paymentGatewayAccount: paymentGatewayAccount)
            })
        }, bluetooth: { [weak self] in
            guard let self = self else { return }
            self.analytics.track(event: .InPersonPayments.cardReaderSelectTypeBluetoothTapped(
                forGatewayID: paymentGatewayAccount.gatewayID,
                countryCode: self.configuration.countryCode))
            self.connectionController.searchAndConnect(onCompletion: { [weak self] result in
                self?.handleConnectionResult(result, paymentGatewayAccount: paymentGatewayAccount)
            })
        }, cancel: { [weak self] in
            guard let self = self else { return }
            self.alertsPresenter.dismiss()
            self.handleConnectionResult(.success(.canceled(.selectReaderType)),
                                        paymentGatewayAccount: paymentGatewayAccount)
        }))
    }

    @MainActor
    private func selectedPaymentGateway() async -> PaymentGatewayAccount? {
        await withCheckedContinuation { continuation in
            let action = CardPresentPaymentAction.selectedPaymentGatewayAccount { paymentGatewayAccount in
                continuation.resume(returning: paymentGatewayAccount)
            }
            stores.dispatch(action)
        }
    }

    private func handleConnectionResult(_ result: Result<CardReaderConnectionResult, Error>,
                                        paymentGatewayAccount: PaymentGatewayAccount) {
        let connectionResult = result.map { connection in
            if case .connected(let reader) = connection {
                self.connectedReader = reader
            }
            return connection
        }

        switch connectionResult {
        case .success(let unwrapped):
            switch unwrapped {
            case .canceled(let source):
                readerConnectionSubject.send(.canceled(source, paymentGatewayAccount))
            case .connected(let reader):
                readerConnectionSubject.send(.completed(reader, paymentGatewayAccount))
            }
        case .failure(let error):
            DDLogError("⛔️ Card Present Payment Preflight failed: \(error.localizedDescription)")
            handlePreflightFailure(error: error)
        }
    }

    private func handlePreflightFailure(error: Error) {
        alertsPresenter.dismiss()
    }

    private func observeConnectedReaders() {
        let action = CardPresentPaymentAction.observeConnectedReaders() { [weak self] readers in
            self?.connectedReader = readers.first
        }
        stores.dispatch(action)
    }
}

enum CardPresentPaymentPreflightError: Error, Equatable {
    case paymentGatewayAccountNotFound
    case failedToAutomaticallyDisconnect(reader: CardReader)
    case localMobileReaderNotSupported
}
