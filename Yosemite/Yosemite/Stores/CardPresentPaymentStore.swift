import Storage
import Hardware
import Networking
import Combine



/// MARK: CardPresentPaymentStore
///
public final class CardPresentPaymentStore: Store {
    // Retaining the reference to the card reader service might end up being problematic.
    // At this point though, the ServiceLocator is part of the WooCommerce binary, so this is a good starting point.
    // If retaining the service here ended up being a problem, we would need to move this Store out of Yosemite and push it up to WooCommerce.
    private let cardReaderService: CardReaderService

    /// Card reader config provider
    ///
    private let commonReaderConfigProvider: CommonReaderConfigProvider

    /// Which backend is the store using? Default to WCPay until told otherwise
    private var usingBackend: CardPresentPaymentStoreBackend = .wcpay

    private let remote: WCPayRemote
    private let stripeRemote: StripeRemote

    private var cancellables: Set<AnyCancellable> = []

    /// We need to be able to cancel the process of collecting a payment.
    private var paymentCancellable: AnyCancellable? = nil

    public init(
        dispatcher: Dispatcher,
        storageManager: StorageManagerType,
        network: Network,
        cardReaderService: CardReaderService
    ) {
        self.cardReaderService = cardReaderService
        self.commonReaderConfigProvider = CommonReaderConfigProvider()
        self.remote = WCPayRemote(network: network)
        self.stripeRemote = StripeRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: CardPresentPaymentAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? CardPresentPaymentAction else {
            assertionFailure("\(String(describing: self)) received an unsupported action")
            return
        }

        switch action {
        case .use(let account):
            use(paymentGatewayAccount: account)
        case .loadAccounts(let siteID, let onCompletion):
            loadAccounts(siteID: siteID,
                         onCompletion: onCompletion)
        case .fetchOrderCustomer(let siteID, let orderID, let completion):
            fetchOrderCustomer(siteID: siteID, orderID: orderID, completion: completion)
        case .captureOrderPayment(let siteID,
                                  let orderID,
                                  let paymentIntentID,
                                  let onCompletion):
            captureOrderPayment(siteID: siteID,
                                orderID: orderID,
                                paymentIntentID: paymentIntentID,
                                onCompletion: onCompletion)
        case .startCardReaderDiscovery(let siteID, let onReaderDiscovered, let onError):
            startCardReaderDiscovery(siteID: siteID, onReaderDiscovered: onReaderDiscovered, onError: onError)
        case .cancelCardReaderDiscovery(let completion):
            cancelCardReaderDiscovery(completion: completion)
        case .connect(let reader, let completion):
            connect(reader: reader, onCompletion: completion)
        case .disconnect(let completion):
            disconnect(onCompletion: completion)
        case .observeConnectedReaders(let completion):
            observeConnectedReaders(onCompletion: completion)
        case .collectPayment(let siteID, let orderID, let parameters, let event, let completion):
            collectPayment(siteID: siteID,
                           orderID: orderID,
                           parameters: parameters,
                           onCardReaderMessage: event,
                           onCompletion: completion)
        case .cancelPayment(let completion):
            cancelPayment(onCompletion: completion)
        case .observeCardReaderUpdateState(onCompletion: let completion):
            observeCardReaderUpdateState(onCompletion: completion)
        case .startCardReaderUpdate:
            startCardReaderUpdate()
        case .reset:
            reset()
        case .checkCardReaderConnected(onCompletion: let completion):
            checkCardReaderConnected(onCompletion: completion)
        case .fetchWCPayCharge(let siteID, let chargeID, let completion):
            fetchCharge(siteID: siteID, chargeID: chargeID, completion: completion)
        }
    }
}


// MARK: - Services
//
private extension CardPresentPaymentStore {
    /// Which backend is the store to use? WCPay or Stripe?
    ///
    enum CardPresentPaymentStoreBackend {
        /// Use WCPay as the backend
        ///
        case wcpay

        /// Use Stripe as the backend
        ///
        case stripe
    }

    func startCardReaderDiscovery(siteID: Int64, onReaderDiscovered: @escaping (_ readers: [CardReader]) -> Void, onError: @escaping (Error) -> Void) {
        do {
            switch usingBackend {
            case .wcpay:
                commonReaderConfigProvider.setContext(siteID: siteID, remote: self.remote)
                try cardReaderService.start(commonReaderConfigProvider)
            case .stripe:
                commonReaderConfigProvider.setContext(siteID: siteID, remote: self.stripeRemote)
                try cardReaderService.start(commonReaderConfigProvider)
            }
        } catch {
            return onError(error)
        }

        // Over simplification. This is the point where we would receive
        // new data via the CardReaderService's stream of discovered readers
        // In here, we should redirect that data to Storage and also up to the UI.
        // For now we are sending the data up to the UI directly
        cardReaderService.discoveredReaders
            .subscribe(Subscribers.Sink(
                receiveCompletion: { result in
                    switch result {
                    case .finished: break
                    case .failure(let error):
                        onError(error)
                    }
                },
                receiveValue: { readers in
                    let supportedReaders = readers.filter({$0.readerType == .chipper || $0.readerType == .stripeM2 || $0.readerType == .wisepad3})
                    onReaderDiscovered(supportedReaders)
                }
            ))
    }

    func cancelCardReaderDiscovery(completion: @escaping (Result<Void, Error>) -> Void) {
        cardReaderService.cancelDiscovery()
            .subscribe(Subscribers.Sink(
                receiveCompletion: { (result) in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .finished:
                        completion(.success(()))
                    }
                }, receiveValue: {
                    _ in }
            ))
    }

    func connect(reader: Yosemite.CardReader, onCompletion: @escaping (Result<Yosemite.CardReader, Error>) -> Void) {
        // We tiptoe around this for now. We will get into error handling later:
        // https://github.com/woocommerce/woocommerce-ios/issues/3734
        // https://github.com/woocommerce/woocommerce-ios/issues/3741
        cardReaderService.connect(reader)
            .subscribe(Subscribers.Sink(receiveCompletion: { (completion) in
                if case let .failure(underlyingError) = completion {
                    onCompletion(.failure(underlyingError))
                }
                // We don't want to propagate successful completion since we already did that by
                // calling onCompletion when a value was received.
            }, receiveValue: { (reader) in
                onCompletion(.success(reader))
            }))
    }

    func disconnect(onCompletion: @escaping (Result<Void, Error>) -> Void) {
        cardReaderService.disconnect().subscribe(Subscribers.Sink(
            receiveCompletion: { error in
                switch error {
                case .failure(let error):
                    onCompletion(.failure(error))
                default:
                    break
                }
            },
            receiveValue: { result in
                onCompletion(.success(result))
            }
        ))
    }

    /// Calls the completion block everytime the list of connected readers changes
    ///
    func observeConnectedReaders(onCompletion: @escaping ([Yosemite.CardReader]) -> Void) {
        cardReaderService.connectedReaders.sink { _ in
        } receiveValue: { readers in
            onCompletion(readers)
        }.store(in: &cancellables)
    }

    func collectPayment(siteID: Int64,
                        orderID: Int64,
                        parameters: PaymentParameters,
                        onCardReaderMessage: @escaping (CardReaderEvent) -> Void,
                        onCompletion: @escaping (Result<PaymentIntent, Error>) -> Void) {
        // Observe status events fired by the card reader
        let readerEventsSubscription = cardReaderService.readerEvents.sink { event in
            onCardReaderMessage(event)
        }

        paymentCancellable = cardReaderService.capturePayment(parameters).sink { error in
            readerEventsSubscription.cancel()
            switch error {
            case .failure(let error):
                onCompletion(.failure(error))
            default:
                break
            }
        } receiveValue: { intent in
            onCompletion(.success(intent))
        }
    }

    func cancelPayment(onCompletion: ((Result<Void, Error>) -> Void)?) {
        paymentCancellable?.cancel()
        paymentCancellable = nil

        cardReaderService.cancelPaymentIntent()
            .subscribe(Subscribers.Sink(receiveCompletion: { value in
            switch value {
            case .failure(let error):
                onCompletion?(.failure(error))
            case .finished:
                break
            }
        }, receiveValue: {
            onCompletion?(.success(()))
        }))
    }

    func observeCardReaderUpdateState(onCompletion: (AnyPublisher<CardReaderSoftwareUpdateState, Never>) -> Void) {
        onCompletion(cardReaderService.softwareUpdateEvents)
    }

    func startCardReaderUpdate() {
        cardReaderService.installUpdate()
    }

    func reset() {
        cardReaderService.disconnect()
            .subscribe(Subscribers.Sink(
                        receiveCompletion: { [weak self] _ in
                            self?.cardReaderService.clear()
                        },
                        receiveValue: { _ in }
            ))
    }

    func checkCardReaderConnected(onCompletion: (AnyPublisher<[CardReader], Never>) -> Void) {
        let publisher = cardReaderService.connectedReaders
            // We only emit values when there is no reader connected, including an initial value
            .prefix(while: { cardReaders in
                cardReaders.count == 0
            })
            // Remove duplicates since we don't want to present the connection modal twice
            .removeDuplicates()
            // Beyond this point, the publisher should emit an empty initial value once
            // and then finish when a reader is connected.
            .eraseToAnyPublisher()

        onCompletion(publisher)
    }
}
private extension CardPresentPaymentStore {
    final class CommonReaderConfigProvider: CardReaderConfigProvider {
        var siteID: Int64?
        var readerConfigRemote: CardReaderCapableRemote?

        public func setContext(siteID: Int64, remote: CardReaderCapableRemote) {
            self.siteID = siteID
            self.readerConfigRemote = remote
        }

        public func fetchToken(completion: @escaping(Result<String, Error>) -> Void) {
            guard let siteID = self.siteID else {
                return
            }

            readerConfigRemote?.loadConnectionToken(for: siteID) { result in
                switch result {
                case .success(let token):
                    completion(.success(token.token))
                case .failure(let error):
                    if let configError = CardReaderConfigError(error: error) {
                        completion(.failure(configError))
                    } else {
                        completion(.failure(error))
                    }
                }
            }
        }

        public func fetchDefaultLocationID(completion: @escaping(Result<String, Error>) -> Void) {
            guard let siteID = self.siteID else {
                return
            }

            readerConfigRemote?.loadDefaultReaderLocation(for: siteID) { result in
                switch result {
                case .success(let location):
                    let readerLocation = location.toReaderLocation(siteID: siteID)
                    completion(.success(readerLocation.id))
                case .failure(let error):
                    if let configError = CardReaderConfigError(error: error) {
                        completion(.failure(configError))
                    } else {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
}

private extension CardReaderConfigError {
    init?(error: Error) {
        guard let dotcomError = error as? DotcomError else {
            return nil
        }
        switch dotcomError {
        case .unknown("store_address_is_incomplete", let message):
            self = .incompleteStoreAddress(adminUrl: URL(string: message ?? ""))
            return
        case .unknown("postal_code_invalid", _):
            self = .invalidPostalCode
            return
        default:
            return nil
        }
    }
}

// MARK: Networking Methods
private extension CardPresentPaymentStore {
    /// Sets the store to use a given payment gateway
    ///
    func use(paymentGatewayAccount: PaymentGatewayAccount) {
        guard paymentGatewayAccount.isWCPay else {
            usingBackend = .stripe
            return
        }

        usingBackend = .wcpay
    }

    /// Loads the account corresponding to the currently selected backend. Deletes the other (if it exists).
    ///
    func loadAccounts(siteID: Int64, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        var error: Error? = nil

        let group = DispatchGroup()
        group.enter()
        loadWCPayAccount(siteID: siteID, onCompletion: { result in
            switch result {
            case .failure(let loadError):
                DDLogError("⛔️ Error synchronizing WCPay Account: \(loadError)")
                error = loadError
            case .success():
                break
            }
            group.leave()
        })

        group.enter()
        loadStripeAccount(siteID: siteID, onCompletion: {result in
            switch result {
            case .failure(let loadError):
                DDLogError("⛔️ Error synchronizing Stripe Account: \(loadError)")
                error = loadError
            case .success():
                break
            }
            group.leave()
        })

        group.notify(queue: .main) {
            guard let error = error else {
                onCompletion(.success(()))
                return
            }
            onCompletion(.failure(error))
        }
    }

    func loadWCPayAccount(siteID: Int64, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        /// Delete any WCPay account present. There can be only one.
        self.deleteStaleAccount(siteID: siteID, gatewayID: WCPayAccount.gatewayID)

        /// Fetch the WCPay account
        remote.loadAccount(for: siteID) { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .success(let wcpayAccount):
                let account = wcpayAccount.toPaymentGatewayAccount(siteID: siteID)
                self.upsertStoredAccountInBackground(readonlyAccount: account)
                onCompletion(.success(()))
            case .failure(let error):
                self.deleteStaleAccount(siteID: siteID, gatewayID: WCPayAccount.gatewayID)
                onCompletion(.failure(error))
            }
        }
    }

    func loadStripeAccount(siteID: Int64, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        /// Delete any Stripe account present. There can be only one.
        self.deleteStaleAccount(siteID: siteID, gatewayID: StripeAccount.gatewayID)

        stripeRemote.loadAccount(for: siteID) { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .success(let stripeAccount):
                let account = stripeAccount.toPaymentGatewayAccount(siteID: siteID)
                self.upsertStoredAccountInBackground(readonlyAccount: account)
                onCompletion(.success(()))
            case .failure(let error):
                self.deleteStaleAccount(siteID: siteID, gatewayID: StripeAccount.gatewayID)
                onCompletion(.failure(error))
            }
        }
    }

    func fetchOrderCustomer(siteID: Int64, orderID: Int64, completion: @escaping (Result<WCPayCustomer, Error>) -> Void) {
        switch usingBackend {
        case .wcpay:
            remote.fetchOrderCustomer(for: siteID, orderID: orderID, completion: completion)
        case .stripe:
            stripeRemote.fetchOrderCustomer(for: siteID, orderID: orderID, completion: completion)
        }
    }

    func captureOrderPayment(siteID: Int64,
                             orderID: Int64,
                             paymentIntentID: String,
                             onCompletion: @escaping (Result<Void, Error>) -> Void) {
        switch usingBackend {
        case .wcpay:
            captureOrderPaymentUsingWCPay(siteID: siteID, orderID: orderID, paymentIntentID: paymentIntentID, onCompletion: onCompletion)
        case .stripe:
            captureOrderPaymentUsingStripe(siteID: siteID, orderID: orderID, paymentIntentID: paymentIntentID, onCompletion: onCompletion)
        }
    }

    func captureOrderPaymentUsingWCPay(siteID: Int64,
                                       orderID: Int64,
                                       paymentIntentID: String,
                                       onCompletion: @escaping (Result<Void, Error>) -> Void) {
        remote.captureOrderPayment(for: siteID, orderID: orderID, paymentIntentID: paymentIntentID, completion: { result in
            switch result {
            case .success(let intent):
                guard intent.status == .succeeded else {
                    DDLogDebug("Unexpected payment intent status \(intent.status) after attempting capture")
                    onCompletion(.failure(CardReaderServiceError.paymentCapture()))
                    return
                }

                onCompletion(.success(()))
            case .failure(let error):
                onCompletion(.failure(PaymentGatewayAccountError(underlyingError: error)))
                return
            }
        })
    }

    func captureOrderPaymentUsingStripe(siteID: Int64,
                                       orderID: Int64,
                                       paymentIntentID: String,
                                       onCompletion: @escaping (Result<Void, Error>) -> Void) {
        stripeRemote.captureOrderPayment(for: siteID, orderID: orderID, paymentIntentID: paymentIntentID, completion: { result in
            switch result {
            case .success(let intent):
                guard intent.status == .succeeded else {
                    DDLogDebug("Unexpected payment intent status \(intent.status) after attempting capture")
                    onCompletion(.failure(CardReaderServiceError.paymentCapture()))
                    return
                }

                onCompletion(.success(()))
            case .failure(let error):
                onCompletion(.failure(PaymentGatewayAccountError(underlyingError: error)))
                return
            }
        })
    }

    func fetchCharge(siteID: Int64, chargeID: String, completion: @escaping (Result<WCPayCharge, Error>) -> Void) {
        switch usingBackend {
        case .wcpay:
            remote.fetchCharge(for: siteID, chargeID: chargeID) { result in
                switch result {
                case .success(let charge):
                    self.upsertCharge(readonlyCharge: charge)
                    completion(.success(charge))
                case .failure(let error):
                    if case .noSuchChargeError(_) = WCPayChargesError(underlyingError: error) {
                        self.deleteCharge(siteID: siteID, chargeID: chargeID)
                    }
                    completion(.failure(error))
                }
            }
        case .stripe:
            break; /// not implemented
        }
    }
}

// MARK: Storage Methods
private extension CardPresentPaymentStore {
    func upsertStoredAccountInBackground(readonlyAccount: PaymentGatewayAccount) {
        let storage = storageManager.viewStorage
        let storageAccount = storage.loadPaymentGatewayAccount(siteID: readonlyAccount.siteID, gatewayID: readonlyAccount.gatewayID) ??
            storage.insertNewObject(ofType: Storage.PaymentGatewayAccount.self)

        storageAccount.update(with: readonlyAccount)
    }

    func deleteStaleAccount(siteID: Int64, gatewayID: String) {
        let storage = storageManager.viewStorage
        guard let storageAccount = storage.loadPaymentGatewayAccount(siteID: siteID, gatewayID: gatewayID) else {
            return
        }

        storage.deleteObject(storageAccount)
        storage.saveIfNeeded()
    }

    func upsertCharge(readonlyCharge: WCPayCharge) {
        let storage = storageManager.viewStorage
        let storageWCPayCharge = existingOrNewWCPayCharge(siteID: readonlyCharge.siteID, chargeID: readonlyCharge.id, in: storage)

        switch readonlyCharge.paymentMethodDetails {
        case .cardPresent(let details):
            upsertCardPresentDetails(details, for: storageWCPayCharge, in: storage)
        case .card(let details):
            upsertCardDetails(details, for: storageWCPayCharge, in: storage)
        case .unknown:
            storageWCPayCharge.cardDetails = nil
            storageWCPayCharge.cardPresentDetails = nil
        }

        storageWCPayCharge.update(with: readonlyCharge)
    }

    private func existingOrNewWCPayCharge(siteID: Int64, chargeID: String, in storage: StorageType) -> Storage.WCPayCharge {
        storage.loadWCPayCharge(siteID: siteID, chargeID: chargeID) ?? storage.insertNewObject(ofType: Storage.WCPayCharge.self)
    }

    private func upsertCardPresentDetails(_ details: WCPayCardPresentPaymentDetails,
                                          for storageWCPayCharge: Storage.WCPayCharge,
                                          in storage: StorageType) {
        let storageCardPresentDetails = storageWCPayCharge.cardPresentDetails ?? storage.insertNewObject(ofType: Storage.WCPayCardPresentPaymentDetails.self)
        let storageReceiptDetails = storageCardPresentDetails.receipt ?? storage.insertNewObject(ofType: Storage.WCPayCardPresentReceiptDetails.self)

        storageCardPresentDetails.update(with: details)
        storageReceiptDetails.update(with: details.receipt)

        storageCardPresentDetails.receipt = storageReceiptDetails

        storageWCPayCharge.cardPresentDetails = storageCardPresentDetails
        storageWCPayCharge.cardDetails = nil
    }

    private func upsertCardDetails(_ details: WCPayCardPaymentDetails,
                                   for storageWCPayCharge: Storage.WCPayCharge,
                                   in storage: StorageType) {
        let storageCardDetails = storageWCPayCharge.cardDetails ?? storage.insertNewObject(ofType: Storage.WCPayCardPaymentDetails.self)
        storageCardDetails.update(with: details)

        storageWCPayCharge.cardDetails = storageCardDetails
        storageWCPayCharge.cardPresentDetails = nil
    }

    func deleteCharge(siteID: Int64, chargeID: String) {
        let storage = storageManager.viewStorage
        guard let charge = storage.loadWCPayCharge(siteID: siteID, chargeID: chargeID) else {
            return
        }

        storage.deleteObject(charge)
        storage.saveIfNeeded()
    }
}

public enum PaymentGatewayAccountError: Error, LocalizedError {
    case orderPaymentCaptureError(message: String?)
    case otherError(error: AnyError)

    init(underlyingError error: Error) {
        guard case let DotcomError.unknown(code, message) = error else {
            self = .otherError(error: error.toAnyError)
            return
        }

        /// See if we recognize this DotcomError code
        ///
        self = ErrorCode(rawValue: code)?.error(message: message ?? Localizations.defaultMessage) ?? .otherError(error: error.toAnyError)
    }

    enum ErrorCode: String {
        case wcpayCaptureError = "wcpay_capture_error"

        func error(message: String) -> PaymentGatewayAccountError {
            switch self {
            case .wcpayCaptureError:
                return .orderPaymentCaptureError(message: message)
            }
        }
    }

    public var errorDescription: String? {
        switch self {
        case .orderPaymentCaptureError(let message):
            /// Return the message directly from the store, e.g. in the case of fractional quantities, which are not allowed
            /// "Payment capture failed to complete with the following message: Error: Invalid integer: 2.5"
            return message
        case .otherError(let error):
            return error.localizedDescription
        }
    }

    enum Localizations {
        static let defaultMessage = NSLocalizedString(
            "An unexpected error occurred with the store's payment gateway when capturing payment for the order",
            comment: "Message presented when an unexpected error occurs with the store's payment gateway."
        )
    }
}

private extension PaymentGatewayAccount {
    var isWCPay: Bool {
        self.gatewayID == WCPayAccount.gatewayID
    }
}

// MARK: - CardReaderCapableRemote
//
public protocol CardReaderCapableRemote {
    func loadConnectionToken(for siteID: Int64,
                             completion: @escaping(Result<ReaderConnectionToken, Error>) -> Void)
    func loadDefaultReaderLocation(for siteID: Int64,
                                   onCompletion: @escaping (Result<RemoteReaderLocation, Error>) -> Void)
}

extension WCPayRemote: CardReaderCapableRemote {}
extension StripeRemote: CardReaderCapableRemote {}

// MARK: - WCPayChargesError
public enum WCPayChargesError: Error, LocalizedError {
    case noSuchChargeError(message: String)
    case otherError(error: AnyError)

    init(underlyingError error: Error) {
        guard case let DotcomError.unknown(code, message) = error,
              let message = message else {
                  self = .otherError(error: error.toAnyError)
                  return
              }

        /// See if we recognize this DotcomError code
        ///
        self = ErrorCode(rawValue: code)?.error(message: message) ?? .otherError(error: error.toAnyError)
    }

    enum ErrorCode: String {
        case getChargeError = "wcpay_get_charge"
        case unknown

        func error(message: String) -> WCPayChargesError? {
            switch self {
            case .getChargeError:
                guard message.starts(with: "Error: No such charge") else {
                    return nil
                }
                return .noSuchChargeError(message: message)
            default:
                return nil
            }
        }
    }

    public var errorDescription: String? {
        switch self {
        case .noSuchChargeError(let message):
            /// Return the message directly from the store
            /// "Error: No such charge: 'ch_3KMVapErrorERROR'"
            return message
        case .otherError(let error):
            return error.localizedDescription
        }
    }
}
