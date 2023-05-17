import Foundation
import Yosemite
import Combine

enum CardReaderPreflightResult {
    case completed(CardReader, PaymentGatewayAccount)
    case canceled(WooAnalyticsEvent.InPersonPayments.CancellationSource, PaymentGatewayAccount)
}

enum CardReaderConnectionResult {
    case connected(CardReader)
    case canceled(WooAnalyticsEvent.InPersonPayments.CancellationSource)
}

final class CardPresentPaymentPreflightController {
    /// Store's ID.
    ///
    private let siteID: Int64

    private let discoveryMethod: CardReaderDiscoveryMethod?

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


    private(set) var readerConnection = CurrentValueSubject<CardReaderPreflightResult?, Never>(nil)

    private let analyticsTracker: CardReaderConnectionAnalyticsTracker

    private let supportDeterminer: CardReaderSupportDeterminer

    private let tapToPayReconnectionController: TapToPayReconnectionController

    init(siteID: Int64,
         discoveryMethod: CardReaderDiscoveryMethod?,
         configuration: CardPresentPaymentsConfiguration,
         rootViewController: UIViewController,
         alertsPresenter: CardPresentPaymentAlertsPresenting,
         onboardingPresenter: CardPresentPaymentsOnboardingPresenting,
         tapToPayReconnectionController: TapToPayReconnectionController = ServiceLocator.tapToPayReconnectionController,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.discoveryMethod = discoveryMethod
        self.configuration = configuration
        self.rootViewController = rootViewController
        self.alertsPresenter = alertsPresenter
        self.onboardingPresenter = onboardingPresenter
        self.tapToPayReconnectionController = tapToPayReconnectionController
        self.stores = stores
        self.analytics = analytics
        self.connectedReader = nil
        self.analyticsTracker = CardReaderConnectionAnalyticsTracker(configuration: configuration,
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

        self.supportDeterminer = CardReaderSupportDeterminer(siteID: siteID, configuration: configuration, stores: stores)
    }

    @MainActor
    func start() async {
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
        alertsPresenter.present(viewModel: CardPresentModalSelectSearchType(
            tapOnIPhoneAction: { [weak self] in
                guard let self = self else { return }
                self.analytics.track(event: .InPersonPayments.cardReaderSelectTypeBuiltInTapped(
                    forGatewayID: paymentGatewayAccount.gatewayID,
                    countryCode: self.configuration.countryCode))
                self.builtInConnectionController.searchAndConnect(onCompletion: { [weak self] result in
                    self?.handleConnectionResult(result, paymentGatewayAccount: paymentGatewayAccount)
                })
            },
            bluetoothAction: { [weak self] in
                guard let self = self else { return }
                self.analytics.track(event: .InPersonPayments.cardReaderSelectTypeBluetoothTapped(
                    forGatewayID: paymentGatewayAccount.gatewayID,
                    countryCode: self.configuration.countryCode))
                self.connectionController.searchAndConnect(onCompletion: { [weak self] result in
                    self?.handleConnectionResult(result, paymentGatewayAccount: paymentGatewayAccount)
                })
            },
            cancelAction: { [weak self] in
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
                readerConnection.send(.canceled(source, paymentGatewayAccount))
            case .connected(let reader):
                readerConnection.send(.completed(reader, paymentGatewayAccount))
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
