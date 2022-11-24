import Combine
import Fakes
import Storage
import Yosemite
@testable import WooCommerce

/// Allows mocking for `CardPresentPaymentAction`.
///
final class MockCardPresentPaymentsStoresManager: DefaultStoresManager {
    /// Mock Storage: InMemory
    ///
    private var storageManager: StorageManagerType

    private var connectedReaders: [CardReader]
    private var discoveredReaders: [CardReader]
    private var failDiscovery: Bool
    private var failUpdate: Bool
    private var failConnection: Bool
    private var softwareUpdateSubject: CurrentValueSubject<CardReaderSoftwareUpdateState, Never> = .init(.none)
    private var paymentExtension: CardPresentPaymentGatewayExtension

    init(connectedReaders: [CardReader],
         discoveredReaders: [CardReader],
         sessionManager: SessionManager,
         storageManager: StorageManagerType = MockStorageManager(),
         failDiscovery: Bool = false,
         failUpdate: Bool = false,
         failConnection: Bool = false,
         paymentExtension: CardPresentPaymentGatewayExtension = .wcpay
    ) {
        self.connectedReaders = connectedReaders
        self.discoveredReaders = discoveredReaders
        self.failDiscovery = failDiscovery
        self.failUpdate = failUpdate
        self.failConnection = failConnection
        self.storageManager = storageManager
        self.paymentExtension = paymentExtension
        super.init(sessionManager: sessionManager)
    }

    override func dispatch(_ action: Action) {
        if let action = action as? CardPresentPaymentAction {
            onCardPresentPaymentAction(action: action)
        } else {
            super.dispatch(action)
        }
    }

    private func onCardPresentPaymentAction(action: CardPresentPaymentAction) {
        switch action {
        case .observeConnectedReaders(let onCompletion):
            onCompletion(connectedReaders)
        case .startCardReaderDiscovery(_, let onReaderDiscovered, let onError):
            guard !failDiscovery else {
                onError(MockErrors.discoveryFailure)
                return
            }
            guard discoveredReaders.isNotEmpty else {
                return
            }
            onReaderDiscovered(discoveredReaders)
        case .connect(let reader, let onCompletion):
            guard !failConnection else {
                onCompletion(Result.failure(MockErrors.connectionFailure))
                return
            }
            guard let batteryLevel = reader.batteryLevel, batteryLevel > 0.1 else {
                return onCompletion(.failure(CardReaderServiceError.connection(underlyingError: .bluetoothConnectionFailedBatteryCriticallyLow)))
            }
            guard !failUpdate else {
                return onCompletion(.failure(CardReaderServiceError.softwareUpdate(underlyingError: .readerSoftwareUpdateFailedBatteryLow, batteryLevel: 0.25)))
            }
            onCompletion(Result.success(reader))
        case .cancelCardReaderDiscovery(let onCompletion):
            onCompletion(Result.success(()))
        case .observeCardReaderUpdateState(onCompletion: let completion):
            completion(softwareUpdateEvents)
        case .startCardReaderUpdate:
            softwareUpdateSubject.send(.started(cancelable: MockFallibleCancelable(onCancel: { [softwareUpdateSubject] in
                softwareUpdateSubject.send(.available)
            })))
            softwareUpdateSubject.send(.installing(progress: 0.5))
            // TODO: send error when we can handle failure state
            softwareUpdateSubject.send(.completed)
            softwareUpdateSubject.send(.none)
        case .loadAccounts(let siteID, let onCompletion):
            insertSamplePaymentGateway(forSiteID: siteID)
            onCompletion(Result.success(()))
        case .loadActivePaymentGatewayExtension(let onCompletion):
            onCompletion(paymentExtension)
        default:
            fatalError("Not available")
        }
    }

    var softwareUpdateEvents: AnyPublisher<CardReaderSoftwareUpdateState, Never> {
        softwareUpdateSubject.eraseToAnyPublisher()
    }
}

extension MockCardPresentPaymentsStoresManager {
    enum MockErrors: Error {
        case discoveryFailure
        case readerUpdateFailure
        case connectionFailure
    }
}

extension MockCardPresentPaymentsStoresManager {
    func simulateSuccessfulUpdate() {
        softwareUpdateSubject.send(.completed)
    }

    func simulateFailedUpdate(error: Error) {
        softwareUpdateSubject.send(.failed(error: error))
    }

    func simulateCancelableUpdate(onCancel: @escaping () -> Void) {
        softwareUpdateSubject.send(.started(cancelable: MockFallibleCancelable(onCancel: {
            onCancel()
            self.softwareUpdateSubject.send(
                .failed(error: CardReaderServiceError.softwareUpdate(
                    underlyingError: .readerSoftwareUpdateFailedInterrupted,
                    batteryLevel: 0.86
                ))
            )
        })))
    }

    func simulateUpdateStarted() {
        softwareUpdateSubject.send(.started(cancelable: nil))
    }

    func simulateUpdateProgress(_ progress: Float) {
        softwareUpdateSubject.send(.installing(progress: progress))
    }

    func simulateOptionalUpdateAvailable() {
        softwareUpdateSubject.send(.available)
    }

    func insertSamplePaymentGateway(forSiteID siteID: Int64) {
        let paymentGatewayAccount = PaymentGatewayAccount
            .fake()
            .copy(
                siteID: siteID,
                gatewayID: "MOCKGATEWAY",
                status: "complete",
                hasPendingRequirements: false,
                hasOverdueRequirements: false,
                isCardPresentEligible: true,
                isLive: true,
                isInTestMode: false
            )
        storageManager.reset()
        let newAccount = storageManager.viewStorage.insertNewObject(ofType: StoragePaymentGatewayAccount.self)
        newAccount.update(with: paymentGatewayAccount)
    }
}
