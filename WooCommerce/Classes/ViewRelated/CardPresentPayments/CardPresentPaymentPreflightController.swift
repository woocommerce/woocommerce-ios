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
    func cancelConnectionAttempt()

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
    private var tapToPayConnectionController: TapToPayCardReaderConnectionController<TapToPayAlertProvider, AlertPresenter>

    private var tapToPayAlertProvider: TapToPayAlertProvider

    private var readerConnectionSubject = CurrentValueSubject<CardReaderPreflightResult?, Never>(nil)
    private let connectionAttemptLock = NSLock()
    private var currentConnectionAttemptID = 0

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
         tapToPayConnectionController: TapToPayCardReaderConnectionController<TapToPayAlertProvider, AlertPresenter>,
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
        self.tapToPayConnectionController = tapToPayConnectionController

        self.supportDeterminer = CardReaderSupportDeterminer(siteID: siteID, configuration: configuration, stores: stores)
    }

    @MainActor
    func start(discoveryMethod: CardReaderDiscoveryMethod?) async {
        let connectionAttemptID = beginConnectionAttempt()
        self.discoveryMethod = discoveryMethod
        observeConnectedReaders()
        await checkForConnectedReader(connectionAttemptID: connectionAttemptID)
    }

    func cancelConnectionAttempt() {
        _ = beginConnectionAttempt()
    }

    @MainActor
    private func checkForConnectedReader(connectionAttemptID: Int) async {
        if let connectedReader = connectedReader,
           let paymentGatewayAccount = await selectedPaymentGateway() {
            // The reader was already connected when the analyticsTracker was created,
            //`so we need to pass it along for properties to be correct
            analyticsTracker.setCandidateReader(connectedReader)
            if connectedReader.discoveryMethod == discoveryMethod,
               paymentGatewayAccount.siteID == siteID {
                return handleConnectionResult(.success(.connected(connectedReader)), paymentGatewayAccount: paymentGatewayAccount)
            } else {
                // Wrong discovery method or different store - disconnect and reconnect
                do {
                    try await automaticallyDisconnectFromReader()
                    analyticsTracker.automaticallyDisconnectedFromReader()
                    checkOnboarding(connectionAttemptID: connectionAttemptID)
                } catch {
                    return handlePreflightFailure(
                        error: CardPresentPaymentPreflightError.failedToAutomaticallyDisconnect(reader: connectedReader))
                }
            }
        } else {
            // If we're not connected, check onboarding
            checkOnboarding(connectionAttemptID: connectionAttemptID)
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

    private func checkOnboarding(connectionAttemptID: Int) {
        // Can't currently make this async without leaking the continuation.
        onboardingPresenter.showOnboardingIfRequired(from: rootViewController) { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                guard self.isCurrentConnectionAttempt(connectionAttemptID) else { return }
                await self.continuePreflight(connectionAttemptID: connectionAttemptID)
            }
        }
    }

    @MainActor
    private func continuePreflight(connectionAttemptID: Int) async {
        // Once onboarding is complete, a Payment Gateway will have been chosen
        guard let paymentGatewayAccount = await selectedPaymentGateway() else {
            DDLogError("⛔️ Cannot proceed with reader connection, no Payment Gateway found")
            return handlePreflightFailure(error: CardPresentPaymentPreflightError.paymentGatewayAccountNotFound)
        }

        await startReaderConnection(using: paymentGatewayAccount, connectionAttemptID: connectionAttemptID)
    }


    private func startReaderConnection(using paymentGatewayAccount: PaymentGatewayAccount, connectionAttemptID: Int) async {
        guard isCurrentConnectionAttempt(connectionAttemptID) else { return }
        let isReconnecting = tapToPayReconnectionController.isReconnecting
        guard !isReconnecting else {
            return adoptReconnection(using: paymentGatewayAccount, connectionAttemptID: connectionAttemptID)
        }
        let tapToPayReaderSupported = await supportDeterminer.deviceSupportsTapToPayReader() && supportDeterminer.siteSupportsTapToPayReader()
        guard isCurrentConnectionAttempt(connectionAttemptID) else { return }

        switch (discoveryMethod, tapToPayReaderSupported) {
        case (.none, true):
            await promptForReaderTypeSelection(paymentGatewayAccount: paymentGatewayAccount)
        case (.bluetoothScan, _),
            (.none, false):
            connectionController.searchAndConnect(onCompletion: { [weak self] result in
                self?.handleConnectionResult(result, paymentGatewayAccount: paymentGatewayAccount)
            })
        case (.tapToPay, true):
            tapToPayConnectionController.searchAndConnect(onCompletion: { [weak self] result in
                self?.handleConnectionResult(result, paymentGatewayAccount: paymentGatewayAccount)
            })
        case (.tapToPay, false):
            handlePreflightFailure(error: CardPresentPaymentPreflightError.tapToPayReaderNotSupported)
        }
    }

    private func beginConnectionAttempt() -> Int {
        connectionAttemptLock.lock()
        defer { connectionAttemptLock.unlock() }
        currentConnectionAttemptID += 1
        return currentConnectionAttemptID
    }

    private func isCurrentConnectionAttempt(_ connectionAttemptID: Int) -> Bool {
        connectionAttemptLock.lock()
        defer { connectionAttemptLock.unlock() }
        return currentConnectionAttemptID == connectionAttemptID
    }

    private func adoptReconnection(using paymentGatewayAccount: PaymentGatewayAccount, connectionAttemptID: Int) {
        tapToPayReconnectionController.showAlertsForReconnection(from: alertsPresenter) { [weak self] result in
            guard let self = self else { return }
            guard self.isCurrentConnectionAttempt(connectionAttemptID) else { return }
            switch self.discoveryMethod {
            case .bluetoothScan:
                Task { [weak self] in
                    try await self?.automaticallyDisconnectFromReader()
                    await self?.startReaderConnection(using: paymentGatewayAccount, connectionAttemptID: connectionAttemptID)
                }
            case .tapToPay, .none:
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
            self.analytics.track(event: .InPersonPayments.cardReaderSelectTypeTapToPayTapped(
                forGatewayID: paymentGatewayAccount.gatewayID,
                countryCode: self.configuration.countryCode))
            self.tapToPayConnectionController.searchAndConnect(onCompletion: { [weak self] result in
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
    case tapToPayReaderNotSupported
}
