import Combine
import Foundation
import iZettleSDK

/// The adapter wrapping the PayPal iZettle SDK
public final class PayPalCardReaderService: NSObject {
    
    private var discoveryCancellable: AnyCancellable?
    private var paymentCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    
    private var discoveredReadersSubject = CurrentValueSubject<[CardReader], Error>([])
    private let connectedReadersSubject = CurrentValueSubject<[CardReader], Never>([])
    private let discoveryStatusSubject = CurrentValueSubject<CardReaderServiceDiscoveryStatus, Never>(.idle)
    private let readerEventsSubject = PassthroughSubject<CardReaderEvent, Never>()
    private let softwareUpdateSubject = CurrentValueSubject<CardReaderSoftwareUpdateState, Never>(.none)
    private let tapToPayCardReaderAcceptToSSubject = PassthroughSubject<Void, Never>()
    
    // PayPal-specific properties
    private let paypalApiKey: String
    
    /// Initialize with PayPal credentials
    /// For POC, we'll use hardcoded sandbox credentials
    public init(apiKey: String = "HARDCODED_SANDBOX_KEY") {
        self.paypalApiKey = apiKey
        super.init()
        
        setupPayPalSDK()
    }
    
    private func setupPayPalSDK() {
        // Initialize PayPal iZettle SDK
        // For POC, we'll implement the basic setup later
        // once we have the actual SDK API details
        DDLogInfo("💳🟢 [PayPalCardReaderService] *** PAYPAL SERVICE CREATED *** API key: \(paypalApiKey)")
        print("💳🟢 [PayPalCardReaderService] *** PAYPAL SERVICE CREATED *** API key: \(paypalApiKey)")
    }
}

// MARK: - CardReaderService conformance
extension PayPalCardReaderService: CardReaderService {
    
    // MARK: - Queries
    public var discoveredReaders: AnyPublisher<[CardReader], Error> {
        discoveredReadersSubject.eraseToAnyPublisher()
    }
    
    public var connectedReaders: AnyPublisher<[CardReader], Never> {
        connectedReadersSubject.eraseToAnyPublisher()
    }
    
    public var readerEvents: AnyPublisher<CardReaderEvent, Never> {
        readerEventsSubject.eraseToAnyPublisher()
    }
    
    public var softwareUpdateEvents: AnyPublisher<CardReaderSoftwareUpdateState, Never> {
        softwareUpdateSubject.eraseToAnyPublisher()
    }
    
    public var tapToPayCardReaderAcceptToSEvents: AnyPublisher<Void, Never> {
        tapToPayCardReaderAcceptToSSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Commands
    
    public func checkSupport(for cardReaderType: CardReaderType,
                             configProvider: CardReaderConfigProvider,
                             discoveryMethod: CardReaderDiscoveryMethod,
                             minimumOperatingSystemVersionOverride: OperatingSystemVersion?) -> Bool {
        
        // For POC, assume PayPal readers are supported
        // In real implementation, check PayPal SDK capabilities
        return true
    }
    
    public func start(_ configProvider: CardReaderConfigProvider,
                      discoveryMethod: CardReaderDiscoveryMethod) throws {
        
        print("💳🟢 [PayPalCardReaderService] *** START DISCOVERY CALLED ***")
        DDLogInfo("💳🟢 [PayPalCardReaderService] *** START DISCOVERY CALLED ***")
        
        // For POC, simulate reader discovery
        // In real implementation, start PayPal reader discovery
        switchStatusToDiscovering()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            print("💳🟢 [PayPalCardReaderService] *** MOCK PAYPAL READER DISCOVERED ***")
            DDLogInfo("💳🟢 [PayPalCardReaderService] *** MOCK PAYPAL READER DISCOVERED ***")
            
            // Simulate finding a PayPal reader
            let mockReader = CardReader(
                serial: "PAYPAL_READER_001",
                vendorIdentifier: "PayPal",
                name: "PayPal Card Reader",
                status: .init(connected: true, remembered: false),
                softwareVersion: "1.0.0",
                batteryLevel: 0.85,
                readerType: .paypalReaderPPR,
                locationId: "loc_test"
            )
            
            self?.discoveredReadersSubject.send([mockReader])
            self?.switchStatusToIdle()
            print("💳🟢 [PayPal] Sent mock reader to discoveredReadersSubject")
        }
    }
    
    public func cancelDiscovery() -> Future<Void, Error> {
        Future { [weak self] promise in
            self?.switchStatusToIdle()
            promise(.success(()))
        }
    }
    
    public func disconnect() -> Future<Void, Error> {
        Future { [weak self] promise in
            self?.connectedReadersSubject.send([])
            promise(.success(()))
        }
    }
    
    public func waitForInsertedCardToBeRemoved() -> Future<Void, Never> {
        Future { promise in
            // For POC, immediately resolve
            promise(.success(()))
        }
    }
    
    public func clear() {
        // Reset PayPal SDK state
        connectedReadersSubject.send([])
        switchStatusToIdle()
    }
    
    public func capturePayment(_ parameters: PaymentIntentParameters) -> AnyPublisher<PaymentIntent, Error> {
        // Basic PayPal payment processing - will be implemented in next steps
        return Future<PaymentIntent, Error> { promise in
            // For POC, simulate a successful payment
            let amountInSmallestUnit = parameters.amount * parameters.stripeSmallestCurrencyUnitMultiplier
            let amount = NSDecimalNumber(decimal: amountInSmallestUnit).uintValue
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                let mockPaymentIntent = PaymentIntent(
                    id: "pi_paypal_\(UUID().uuidString)",
                    status: .succeeded,
                    created: Date(),
                    amount: amount,
                    currency: parameters.currency,
                    metadata: [:],
                    charges: []
                )
                promise(.success(mockPaymentIntent))
            }
        }.eraseToAnyPublisher()
    }
    
    public func retryActivePaymentIntent() -> AnyPublisher<PaymentIntent, Error> {
        // For POC, not implemented
        return Fail(error: CardReaderServiceError.retryNotPossibleNoActivePayment)
            .eraseToAnyPublisher()
    }
    
    public func cancelPaymentIntent() -> Future<Void, Error> {
        Future { promise in
            promise(.success(()))
        }
    }
    
    public func refundPayment(parameters: RefundParameters) -> AnyPublisher<String, Error> {
        // For POC, simulate refund
        return Just("success")
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func cancelRefund() -> AnyPublisher<Void, Error> {
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func connect(_ reader: CardReader, options: CardReaderConnectionOptions?) -> AnyPublisher<CardReader, Error> {
        return Future<CardReader, Error> { [weak self] promise in
            // Simulate connection
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.connectedReadersSubject.send([reader])
                promise(.success(reader))
            }
        }.eraseToAnyPublisher()
    }
    
    public func installUpdate() -> Void {
        // For POC, no-op
    }
}

// MARK: - Discovery status management
private extension PayPalCardReaderService {
    func switchStatusToIdle() {
        updateDiscoveryStatus(to: .idle)
        resetDiscoveredReadersSubject()
    }
    
    func switchStatusToDiscovering() {
        updateDiscoveryStatus(to: .discovering)
    }
    
    func switchStatusToFault(error: Error) {
        updateDiscoveryStatus(to: .fault)
        resetDiscoveredReadersSubject(error: error)
    }
    
    func updateDiscoveryStatus(to newStatus: CardReaderServiceDiscoveryStatus) {
        discoveryStatusSubject.send(newStatus)
    }
    
    func resetDiscoveredReadersSubject(error: Error? = nil) {
        if let error = error {
            let underlyingError = UnderlyingError(with: error)
            discoveredReadersSubject.send(completion:
                    .failure(CardReaderServiceError.discovery(underlyingError: underlyingError))
            )
        }
        discoveredReadersSubject.send(completion: .finished)
        discoveredReadersSubject = CurrentValueSubject<[CardReader], Error>([])
    }
}
