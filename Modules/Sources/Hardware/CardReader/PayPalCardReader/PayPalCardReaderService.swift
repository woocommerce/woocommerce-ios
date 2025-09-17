import Combine
import Foundation
import iZettleSDK

/// Bridge between CardReaderConfigProvider and iZettleSDKAuthorizationProvider
private class PayPalConfigAuthProvider: NSObject, iZettleSDKAuthorizationProvider {
    private let configProvider: CardReaderConfigProvider
    
    init(configProvider: CardReaderConfigProvider) {
        self.configProvider = configProvider
        super.init()
    }
    
    func authorizeAccount(completion: @escaping iZettleAuthorizationCompletion) {
        print("💳🔐 [PayPalConfigAuthProvider] authorizeAccount called")
        
        configProvider.fetchToken { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let accessToken):
                    do {
                        // Create iZettle token with the access token from config provider
                        let token = try iZettleSDKOAuthToken(
                            accessToken: accessToken,
                            expiresIn: 7200, // 2 hours default
                            refreshToken: "no-refresh"
                        )
                        print("💳✅ [PayPalConfigAuthProvider] Authorization successful")
                        completion(token, nil)
                    } catch {
                        print("💳❌ [PayPalConfigAuthProvider] Failed to create token: \(error)")
                        completion(nil, error)
                    }
                    
                case .failure(let error):
                    print("💳❌ [PayPalConfigAuthProvider] Failed to fetch token: \(error)")
                    completion(nil, error)
                }
            }
        }
    }
    
    func verifyAccount(uuid: UUID, completion: @escaping iZettleAuthorizationCompletion) {
        print("💳🔐 [PayPalConfigAuthProvider] verifyAccount called for UUID: \(uuid)")
        // For verification, reuse the same authorization flow
        authorizeAccount(completion: completion)
    }
}

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

    // PayPal/Zettle SDK state
    private var isSDKStarted: Bool = false
    private var configProvider: CardReaderConfigProvider?

    public override init() {
        super.init()
        print("💳🔧 [PayPalCardReaderService] Initialized - waiting for configuration")
    }

    // MARK: - PayPal SDK Configuration
    
    private func startPayPalSDK(with configProvider: CardReaderConfigProvider) throws {
        guard !isSDKStarted else {
            print("💳✅ [PayPalCardReaderService] SDK already started")
            return
        }
        
        print("💳🟢 [PayPalCardReaderService] Starting iZettle SDK with config provider")
        
        // Store config provider for token fetching
        self.configProvider = configProvider
        
        // Create custom auth provider that uses the config provider to fetch tokens
        let authProvider = PayPalConfigAuthProvider(configProvider: configProvider)
        
        do {
            var isDebug = false
//#if DEBUG
//            isDebug = true
//#endif

            iZettleSDK.shared().start(with: authProvider, enableDeveloperMode: isDebug)

            DDLogInfo("💳✅ [PayPalCardReaderService] iZettle SDK initialized with config provider successfully")
            print("💳✅ [PayPalCardReaderService] iZettle SDK ready with site-managed authentication!")
            isSDKStarted = true

        } catch {
            DDLogError("💳❌ [PayPalCardReaderService] Failed to initialize iZettle SDK: \(error)")
            print("💳❌ [PayPalCardReaderService] SDK initialization failed: \(error)")
            isSDKStarted = false
            throw CardReaderServiceError.discovery(underlyingError: UnderlyingError(with: error))
        }
    }

    /// Fallback: Basic OAuth flow - use this to capture a real JWT token for analysis
    private func setupBasicOAuthSDK() {
        print("💳⚠️ [PayPalCardReaderService] Plugin authentication not available, falling back to basic OAuth")
        print("💳ℹ️ [PayPalCardReaderService] This will show PayPal login screen during payment")
        
        do {
            // Use real Zettle client ID for testing - get this from Zettle Developer Portal
            let clientID = "YOUR_PAYPAL_CLIENT_ID" // Get from https://developer.zettle.com/
            let callbackURL = URL(string: "woocommerce://paypal-auth")! // Your app's custom URL scheme

            let authenticationProvider = try iZettleSDKAuthorization(
                clientID: clientID,
                callbackURL: callbackURL
            )

            // Start the SDK with the authentication provider
            var isDebug = false
//#if DEBUG
//            isDebug = true
//#endif

            iZettleSDK.shared().start(with: authenticationProvider, enableDeveloperMode: isDebug)

            DDLogInfo("💳🟢 [PayPalCardReaderService] iZettle SDK initialized with basic OAuth successfully")
            print("💳🟢 [PayPalCardReaderService] iZettle SDK initialized with basic OAuth successfully")

            print("💳✅ [PayPalCardReaderService] iZettle SDK ready - login will be handled automatically during payment")

        } catch {
            DDLogError("💳❌ [PayPalCardReaderService] Failed to initialize iZettle SDK: \(error)")
            print("💳❌ [PayPalCardReaderService] Failed to initialize iZettle SDK: \(error)")
            print("💳⚠️ [PayPalCardReaderService] Configure WooCommerce site URL and PayPal plugin for seamless auth")
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

        // PayPal readers are supported on iOS
        return cardReaderType.isPayPal
    }

    public func start(_ configProvider: CardReaderConfigProvider,
                      discoveryMethod: CardReaderDiscoveryMethod) throws {

        print("💳🚀 [PayPalCardReaderService] Starting with config provider")
        DDLogInfo("💳🚀 [PayPalCardReaderService] Starting with config provider")

        // Start the PayPal SDK with config provider
        try startPayPalSDK(with: configProvider)
        
        // Start reader discovery
        switchStatusToDiscovering()

        // For POC, simulate finding iZettle readers after SDK startup
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
        print("💳🧹 [PayPalCardReaderService] Clearing service state")
        isSDKStarted = false
        configProvider = nil
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
                    charges: [Charge(id: paymentInfo.transactionId,
                                     amount: paymentInfo.amount.uintValue,
                                     currency: parameters.currency,
                                     status: .succeeded,
                                     description: paymentInfo.description,
                                     metadata: nil,
                                     paymentMethod: .cardPresent(
                                        details: CardPresentTransactionDetails(
                                            last4: String(paymentInfo.obfuscatedPan.suffix(4)),
                                            expMonth: 1,
                                            expYear: 1,
                                            cardholderName: nil,
                                            brand: CardBrand(rawValue: paymentInfo.cardBrand) ?? .unknown,
                                            generatedCard: nil,
                                            receipt: nil,
                                            emvAuthData: paymentInfo.entryMode,
                                            wallet: nil,
                                            network: nil)))]
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
