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

        // Initialize the iZettle SDK immediately
        setupPayPalSDK()
    }

    private func setupPayPalSDK() {
        DDLogInfo("💳🟢 [PayPalCardReaderService] Initializing iZettle SDK")
        print("💳🟢 [PayPalCardReaderService] Initializing iZettle SDK")

        do {
            // Create authentication provider with OAuth 2.0 client ID and redirect URI
            // For POC: Use sandbox credentials - replace with real values from Zettle Developer Portal
            let clientID = "YOUR_PAYPAL_CLIENT_ID" // Get from https://developer.zettle.com/
            let callbackURL = URL(string: "woocommerce://paypal-auth")! // Your app's custom URL scheme

            let authenticationProvider = try iZettleSDKAuthorization(
                clientID: clientID,
                callbackURL: callbackURL
            )

            // Start the SDK with the authentication provider
            var isDebug = false
#if DEBUG
            isDebug = true
#endif
            

            iZettleSDK.shared().start(with: authenticationProvider, enableDeveloperMode: isDebug)

            DDLogInfo("💳🟢 [PayPalCardReaderService] iZettle SDK initialized successfully")
            print("💳🟢 [PayPalCardReaderService] iZettle SDK initialized successfully")

            print("💳✅ [PayPalCardReaderService] iZettle SDK ready - login will be handled automatically during payment")

        } catch {
            DDLogError("💳❌ [PayPalCardReaderService] Failed to initialize iZettle SDK: \(error)")
            print("💳❌ [PayPalCardReaderService] Failed to initialize iZettle SDK: \(error)")
            print("💳⚠️ [PayPalCardReaderService] Make sure to set real client ID and callback URL")
        }
    }

    /// Gets the current view controller for presenting payment UI
    /// Works with both UIKit and SwiftUI contexts
    private func getCurrentViewController() -> UIViewController? {
        // First try to get from UIApplication (works in both UIKit and SwiftUI)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {

            var currentViewController = rootViewController
            while let presentedViewController = currentViewController.presentedViewController {
                currentViewController = presentedViewController
            }

            return currentViewController
        }

        // Fallback: Try the legacy keyWindow approach
        if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
           let rootViewController = keyWindow.rootViewController {

            var currentViewController = rootViewController
            while let presentedViewController = currentViewController.presentedViewController {
                currentViewController = presentedViewController
            }

            return currentViewController
        }

        // Last resort: Create a temporary view controller
        print("💳⚠️ [PayPalCardReaderService] No view controller found, creating temporary one")
        return UIViewController()
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

        // Real iZettle reader discovery
        switchStatusToDiscovering()

        // For POC, simulate finding iZettle readers
        // In production, iZettle SDK handles reader discovery automatically during payment
        // There's no explicit "discover readers" API - readers are found when payment starts

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            print("💳🟢 [PayPalCardReaderService] Simulating iZettle reader discovery")
            DDLogInfo("💳🟢 [PayPalCardReaderService] Simulating iZettle reader discovery")

            // Create a mock iZettle reader for POC
            let mockReader = CardReader(
                serial: "IZETTLE_READER_001",
                vendorIdentifier: "PayPal",
                name: "iZettle Card Reader",
                status: .init(connected: false, remembered: false),
                softwareVersion: "1.0.0",
                batteryLevel: 0.85,
                readerType: .paypalReaderPPR,
                locationId: nil
            )

            self?.discoveredReadersSubject.send([mockReader])
            self?.switchStatusToIdle()
            print("💳🟢 [PayPalCardReaderService] Mock iZettle reader discovered")
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
        return Future<PaymentIntent, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(CardReaderServiceError.paymentCapture(underlyingError: .unexpectedSDKError)))
                return
            }

            print("💳💰 [PayPalCardReaderService] Starting payment capture for amount: \(parameters.amount)")
            DDLogInfo("💳💰 [PayPalCardReaderService] Starting payment capture for amount: \(parameters.amount)")

            // Convert amount for iZettle (uses NSDecimalNumber)
            let amount = NSDecimalNumber(decimal: parameters.amount)
            let reference = "WooOrder_\(parameters.metadata?["order_id"] ?? UUID().uuidString)"

            let sdk = iZettleSDK.shared()

            // Get the current view controller for presenting the payment UI
            guard let currentViewController = self.getCurrentViewController() else {
                print("💳❌ [PayPalCardReaderService] No view controller available for payment UI")
                promise(.failure(CardReaderServiceError.paymentCapture(underlyingError: .unexpectedSDKError)))
                return
            }

            // iZettle SDK handles authentication automatically during charge
            // The SDK will present login UI if needed when charge() is called
            performPayment(sdk: sdk, amount: amount, reference: reference,
                           currentViewController: currentViewController, promise: promise,
                           parameters: parameters)
        }.eraseToAnyPublisher()
    }

    /// Performs the actual payment using the iZettle SDK
    private func performPayment(sdk: iZettleSDK,
                                amount: NSDecimalNumber,
                                reference: String,
                                currentViewController: UIViewController,
                                promise: @escaping (Result<PaymentIntent, Error>) -> Void,
                                parameters: PaymentIntentParameters) {
        // Use the real iZettle SDK payment flow
        sdk.charge(amount: amount,
                   tippingStyle: .none,
                   reference: reference,
                   presentFrom: currentViewController) { paymentInfo, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("💳❌ [PayPalCardReaderService] Payment failed: \(error)")
                    DDLogError("💳❌ [PayPalCardReaderService] Payment failed: \(error)")
                    promise(.failure(error))
                    return
                }

                guard let paymentInfo = paymentInfo else {
                    print("💳❌ [PayPalCardReaderService] No payment info returned")
                    promise(.failure(CardReaderServiceError.paymentCapture(underlyingError: .unexpectedSDKError)))
                    return
                }

                // Convert iZettle payment result to PaymentIntent
                let paymentIntent = PaymentIntent(
                    id: paymentInfo.referenceNumber,
                    status: .succeeded,
                    created: Date(),
                    amount: paymentInfo.amount.uintValue,
                    currency: parameters.currency,
                    metadata: parameters.metadata,
                    charges: []
                )

                print("💳✅ [PayPalCardReaderService] Payment succeeded: \(paymentIntent.id)")
                DDLogInfo("💳✅ [PayPalCardReaderService] Payment succeeded: \(paymentIntent.id)")
                promise(.success(paymentIntent))
            }
        }
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

    /// Presents the PayPal/Zettle settings view for account management
    public func presentSettings(from viewController: UIViewController? = nil) {
        let sdk = iZettleSDK.shared()

        // Get the current view controller if none provided
        let presentingViewController = viewController ?? getCurrentViewController()

        guard let presentingViewController = presentingViewController else {
            print("💳❌ [PayPalCardReaderService] No view controller available for settings")
            return
        }

        // Configure settings - enable tipping settings for PayPal readers
        let configuration = IZSDKSettingsConfiguration(paypalReaderTippingSettingsEnabled: true)

        print("💳⚙️ [PayPalCardReaderService] Presenting PayPal settings")
        DDLogInfo("💳⚙️ [PayPalCardReaderService] Presenting PayPal settings")

        // Present the settings view
        sdk.presentSettings(from: presentingViewController, configuration: configuration)
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
