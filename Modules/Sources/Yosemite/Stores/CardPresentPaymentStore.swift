import Foundation
import Storage
import Hardware
import Networking
import Combine
import enum WooFoundation.CountryCode

// MARK: CardPresentPaymentStore
///
public final class CardPresentPaymentStore: Store {
    // Retaining the reference to the card reader service might end up being problematic.
    // At this point though, the ServiceLocator is part of the WooCommerce binary, so this is a good starting point.
    // If retaining the service here ended up being a problem, we would need to move this Store out of Yosemite and push it up to WooCommerce.
    private let cardReaderService: CardReaderService

    /// Card reader config provider
    ///
    private let commonReaderConfigProvider: CommonReaderConfigProviding

    private var paymentGatewayAccount: PaymentGatewayAccount? {
        didSet {
            if paymentGatewayAccount != oldValue {
                // If we switched accounts, disconnect any connected reader
                // as its connection token would be tied to the other account
                commonReaderConfigProvider.resetContext()
                disconnect(onCompletion: { _ in })
            }
        }
    }

    /// Which backend is the store using? Default to WCPay until told otherwise
    private var usingBackend: CardPresentPaymentsPlugin {
        guard let paymentGatewayAccount else {
            return .wcPay
        }

        return paymentGatewayAccount.isWCPay ? .wcPay : .stripe
    }

    private let remote: WCPayRemote
    private let stripeRemote: StripeRemote

    private var cancellables: Set<AnyCancellable> = []

    /// We need to be able to cancel the process of collecting a payment.
    private var paymentCancellable: AnyCancellable? = nil

    /// We need to be able to cancel the process of refunding a payment.
    private var refundCancellable: AnyCancellable? = nil

    public init(
        dispatcher: Dispatcher,
        storageManager: StorageManagerType,
        network: Network,
        cardReaderService: CardReaderService,
        cardReaderConfigProvider: CommonReaderConfigProviding
    ) {
        self.cardReaderService = cardReaderService
        self.commonReaderConfigProvider = cardReaderConfigProvider
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
        case .selectedPaymentGatewayAccount(let completion):
            completion(paymentGatewayAccount)
        case .loadActivePaymentGatewayExtension(let completion):
            loadActivePaymentGateway(onCompletion: completion)
        case .loadAccounts(let siteID, let onCompletion):
            loadAccounts(siteID: siteID,
                         onCompletion: onCompletion)
        case .checkDeviceSupport(let siteID,
                                 let cardReaderType,
                                 let discoveryMethod,
                                 let minimumOperatingSystemVersionOverride,
                                 let completion):
            checkDeviceSupport(siteID: siteID,
                               cardReaderType: cardReaderType,
                               discoveryMethod: discoveryMethod,
                               minimumOperatingSystemVersionOverride: minimumOperatingSystemVersionOverride,
                               onCompletion: completion)
        case .startCardReaderDiscovery(let siteID, let discoveryMethod, let onReaderDiscovered, let onError):
            startCardReaderDiscovery(siteID: siteID,
                                     discoveryMethod: discoveryMethod,
                                     onReaderDiscovered: onReaderDiscovered,
                                     onError: onError)
        case .cancelCardReaderDiscovery(let completion):
            cancelCardReaderDiscovery(completion: completion)
        case .connect(let reader, let options, let completion):
            connect(reader: reader, options: options, onCompletion: completion)
        case .disconnect(let completion):
            disconnect(onCompletion: completion)
        case .observeConnectedReaders(let completion):
            observeConnectedReaders(onCompletion: completion)
        case .collectPayment(let siteID,
                             let orderID,
                             let parameters,
                             let countryCode,
                             let terminalPaymentPreparationEnabled,
                             let event,
                             let processPaymentCompletion,
                             let completion):
            collectPayment(siteID: siteID,
                           orderID: orderID,
                           parameters: parameters,
                           countryCode: countryCode,
                           terminalPaymentPreparationEnabled: terminalPaymentPreparationEnabled,
                           onCardReaderMessage: event,
                           onProcessingCompletion: processPaymentCompletion,
                           onCompletion: completion)
        case .retryPayment(let siteID,
                           let orderID,
                           let countryCode,
                           let terminalPaymentPreparationEnabled,
                           let event,
                           let processPaymentCompletion,
                           let completion):
            retryActivePayment(siteID: siteID,
                               orderID: orderID,
                               countryCode: countryCode,
                               terminalPaymentPreparationEnabled: terminalPaymentPreparationEnabled,
                               onCardReaderMessage: event,
                               onProcessingCompletion: processPaymentCompletion,
                               onCompletion: completion)
        case .cancelPayment(let completion):
            cancelPayment(onCompletion: completion)
        case .refundPayment(let parameters, let onCardReaderMessage, let completion):
            refundPayment(parameters: parameters, onCardReaderMessage: onCardReaderMessage, onCompletion: completion)
        case .cancelRefund(let completion):
            cancelRefund(onCompletion: completion)
        case .observeCardReaderUpdateState(onCompletion: let completion):
            observeCardReaderUpdateState(onCompletion: completion)
        case .observeTapToPayCardReaderAcceptToS(let completion):
            observeTapToPayCardReaderAcceptToS(onCompletion: completion)
        case .startCardReaderUpdate:
            startCardReaderUpdate()
        case .reset(let onCompletion):
            reset(onCompletion: onCompletion)
        case .publishCardReaderConnections(onCompletion: let completion):
            publishCardReaderConnections(onCompletion: completion)
        case .fetchWCPayCharge(let siteID, let chargeID, let completion):
            fetchCharge(siteID: siteID, chargeID: chargeID, completion: completion)
        case .observeCardReaderReconnectionState(let completion):
            observeCardReaderReconnectionState(onCompletion: completion)
        case .cancelReconnection(let completion):
            cancelReconnection(onCompletion: completion)
        }
    }
}


// MARK: - Services
//
private extension CardPresentPaymentStore {
    func checkDeviceSupport(siteID: Int64,
                            cardReaderType: CardReaderType,
                            discoveryMethod: CardReaderDiscoveryMethod,
                            minimumOperatingSystemVersionOverride: OperatingSystemVersion?,
                            onCompletion: (Bool) -> Void) {
        prepareConfigProvider(siteID: siteID)
        onCompletion(cardReaderService.checkSupport(
            for: cardReaderType,
            configProvider: commonReaderConfigProvider,
            discoveryMethod: discoveryMethod,
            minimumOperatingSystemVersionOverride: minimumOperatingSystemVersionOverride))
    }

    func prepareConfigProvider(siteID: Int64) {
        switch usingBackend {
        case .wcPay:
            commonReaderConfigProvider.setContext(siteID: siteID, remote: self.remote)
        case .stripe:
            commonReaderConfigProvider.setContext(siteID: siteID, remote: self.stripeRemote)
        }
    }

    func startCardReaderDiscovery(siteID: Int64,
                                  discoveryMethod: CardReaderDiscoveryMethod,
                                  onReaderDiscovered: @escaping (_ readers: [CardReader]) -> Void,
                                  onError: @escaping (Error) -> Void) {
        prepareConfigProvider(siteID: siteID)
        do {
            try cardReaderService.start(commonReaderConfigProvider, discoveryMethod: discoveryMethod)
        } catch {
            onError(error)
            return
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
                    let supportedReaders = readers.filter({
                        $0.readerType == .chipper ||
                        $0.readerType == .stripeM2 ||
                        $0.readerType == .wisepad3 ||
                        $0.readerType == .tapToPay
                    })
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

    func connect(reader: Yosemite.CardReader,
                 options: CardReaderConnectionOptions?,
                 onCompletion: @escaping (Result<Yosemite.CardReader, Error>) -> Void) {
        // We tiptoe around this for now. We will get into error handling later:
        // https://github.com/woocommerce/woocommerce-ios/issues/3734
        // https://github.com/woocommerce/woocommerce-ios/issues/3741
        cardReaderService.connect(reader, options: options)
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
                        countryCode: CountryCode,
                        terminalPaymentPreparationEnabled: Bool,
                        onCardReaderMessage: @escaping (CardReaderEvent) -> Void,
                        onProcessingCompletion: @escaping (PaymentIntent) -> Void,
                        onCompletion: @escaping (Result<PaymentIntent, Error>) -> Void) {
        // Observe status events fired by the card reader
        let readerEventsSubscription = cardReaderService.readerEvents.sink { event in
            onCardReaderMessage(event)
        }

        paymentCancellable = handlePaymentEvents(from: cardReaderService.capturePayment(parameters) { intent in
            self.prepareTerminalPayment(siteID: siteID,
                                        orderID: orderID,
                                        paymentIntent: intent,
                                        countryCode: countryCode,
                                        terminalPaymentPreparationEnabled: terminalPaymentPreparationEnabled)
        },
                                                 readerEventsSubscription: readerEventsSubscription,
                                                 siteID: siteID,
                                                 orderID: orderID,
                                                 onCardReaderMessage: onCardReaderMessage,
                                                 onProcessingCompletion: onProcessingCompletion,
                                                 onCompletion: onCompletion)
    }

    private func handlePaymentEvents(from paymentEventPublisher: AnyPublisher<PaymentIntent, Error>,
                                     readerEventsSubscription: AnyCancellable,
                                     siteID: Int64,
                                     orderID: Int64,
                                     onCardReaderMessage: @escaping (CardReaderEvent) -> Void,
                                     onProcessingCompletion: @escaping (PaymentIntent) -> Void,
                                     onCompletion: @escaping (Result<PaymentIntent, Error>) -> Void) -> AnyCancellable? {
        return paymentEventPublisher.handleEvents(receiveOutput: { intent in
            onProcessingCompletion(intent)
        })
        .flatMap { intent in
            Publishers.CombineLatest(
                self.cardReaderService.waitForInsertedCardToBeRemoved()
                    .handleEvents(receiveOutput: {
                        onCardReaderMessage(.cardRemovedAfterClientSidePaymentCapture)
                    })
                    .map { intent },
                self.captureOrderPaymentOnSite(siteID: siteID, orderID: orderID, paymentIntent: intent)
            )
        }
        .sink { completion in
            readerEventsSubscription.cancel()
            switch completion {
            case .failure(let error):
                onCompletion(.failure(error))
            default:
                break
            }
        } receiveValue: { intent, captureOrderPaymentResult in
            switch captureOrderPaymentResult {
            case .success:
                onCompletion(.success(intent))
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    func retryActivePayment(siteID: Int64,
                            orderID: Int64,
                            countryCode: CountryCode,
                            terminalPaymentPreparationEnabled: Bool,
                            onCardReaderMessage: @escaping (CardReaderEvent) -> Void,
                            onProcessingCompletion: @escaping (PaymentIntent) -> Void,
                            onCompletion: @escaping (Result<PaymentIntent, Error>) -> Void) {
        let readerEventsSubscription = cardReaderService.readerEvents.sink { event in
            onCardReaderMessage(event)
        }

        paymentCancellable = handlePaymentEvents(from: cardReaderService.retryActivePaymentIntent { intent in
            self.prepareTerminalPayment(siteID: siteID,
                                        orderID: orderID,
                                        paymentIntent: intent,
                                        countryCode: countryCode,
                                        terminalPaymentPreparationEnabled: terminalPaymentPreparationEnabled)
        },
                                                 readerEventsSubscription: readerEventsSubscription,
                                                 siteID: siteID,
                                                 orderID: orderID,
                                                 onCardReaderMessage: onCardReaderMessage,
                                                 onProcessingCompletion: onProcessingCompletion,
                                                 onCompletion: onCompletion)
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

    func refundPayment(parameters: RefundParameters, onCardReaderMessage: @escaping (CardReaderEvent) -> Void, onCompletion: ((Result<Void, Error>) -> Void)?) {
        // Observes status events fired by the card reader.
        let readerEventsSubscription = cardReaderService.readerEvents.sink { event in
            onCardReaderMessage(event)
        }

        refundCancellable = cardReaderService.refundPayment(parameters: parameters)
            .sink { error in
                readerEventsSubscription.cancel()
                switch error {
                case .failure(let error):
                    DDLogError("⛔️ Error during client-side refund: \(error.localizedDescription)")
                    onCompletion?(.failure(error))
                case .finished:
                    break
                }
            } receiveValue: { status in
                DDLogInfo("💳 Refund Success: \(status)")
                onCompletion?(.success(()))
            }
    }

    func cancelRefund(onCompletion: ((Result<Void, Error>) -> Void)?) {
        refundCancellable?.cancel()
        refundCancellable = nil

        cardReaderService.cancelRefund()
            .sink { error in
                switch error {
                case .failure(let error):
                    DDLogError("⛔️ Error cancelling client-side refund: \(error.localizedDescription)")
                    onCompletion?(.failure(error))
                case .finished:
                    break
                }
            } receiveValue: {
                DDLogInfo("🍁 Refund cancelled successfully!")
                onCompletion?(.success(()))
            }
            .store(in: &cancellables)
    }

    func observeCardReaderUpdateState(onCompletion: (AnyPublisher<CardReaderSoftwareUpdateState, Never>) -> Void) {
        onCompletion(cardReaderService.softwareUpdateEvents)
    }

    func observeTapToPayCardReaderAcceptToS(onCompletion: @escaping (AnyPublisher<Void, Never>) -> Void) {
        onCompletion(cardReaderService.tapToPayCardReaderAcceptToSEvents)
    }

    func startCardReaderUpdate() {
        cardReaderService.installUpdate()
    }

    func reset(onCompletion: @escaping () -> Void) {
        commonReaderConfigProvider.resetContext()

        cardReaderService.disconnect()
            .subscribe(Subscribers.Sink(
                        receiveCompletion: { [weak self] _ in
                            self?.cardReaderService.clear()
                            onCompletion()
                        },
                        receiveValue: { _ in }
            ))
    }

    func publishCardReaderConnections(onCompletion: (AnyPublisher<[CardReader], Never>) -> Void) {
        let publisher = cardReaderService.connectedReaders
            .removeDuplicates()
            .eraseToAnyPublisher()

        onCompletion(publisher)
    }

    func observeCardReaderReconnectionState(onCompletion: (AnyPublisher<CardReaderReconnectionState, Never>) -> Void) {
        onCompletion(cardReaderService.reconnectionEvents)
    }

    func cancelReconnection(onCompletion: @escaping (Result<Void, Error>) -> Void) {
        cardReaderService.cancelReconnection()
            .sink(
                receiveCompletion: { result in
                    switch result {
                    case .failure(let error):
                        onCompletion(.failure(error))
                    case .finished:
                        break
                    }
                },
                receiveValue: {
                    onCompletion(.success(()))
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: Networking Methods
private extension CardPresentPaymentStore {
    /// Sets the store to use a given payment gateway
    ///
    func use(paymentGatewayAccount: PaymentGatewayAccount) {
        self.paymentGatewayAccount = paymentGatewayAccount
    }

    func loadActivePaymentGateway(onCompletion: (CardPresentPaymentsPlugin) -> Void) {
        onCompletion(usingBackend)
    }

    /// Loads the account corresponding to the currently selected backend. Deletes the other (if it exists).
    ///
    func loadAccounts(siteID: Int64, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        var error: Error? = nil
        var hasSuccess: Bool? = nil

        let group = DispatchGroup()
        group.enter()
        loadWCPayAccount(siteID: siteID, onCompletion: { result in
            switch result {
            case .failure(let loadError):
                DDLogError("⛔️ Error synchronizing WCPay Account: \(loadError)")
                error = loadError
            case .success:
                hasSuccess = true
            }
            group.leave()
        })

        group.enter()
        loadStripeAccount(siteID: siteID, onCompletion: {result in
            switch result {
            case .failure(let loadError):
                DDLogError("⛔️ Error synchronizing Stripe Account: \(loadError)")
                error = loadError
            case .success:
                hasSuccess = true
            }
            group.leave()
        })

        group.notify(queue: .main) {
            switch (hasSuccess, error) {
            case (true, _):
                // If either succeeds, the load is successful
                onCompletion(.success(()))
            case (_, .some(let error)):
                // If we have an error, and no success, the load fails
                onCompletion(.failure(error))
            case (_, .none):
                // This... shouldn't really happen.
                onCompletion(.failure(CardPresentPaymentStoreError.unknownErrorFetchingAccounts))
            }
        }
    }

    func loadWCPayAccount(siteID: Int64, onCompletion: @escaping (Result<Void, Error>) -> Void) {

        /// Fetch the WCPay account
        remote.loadAccount(for: siteID) { [weak self] result in
            guard let self else {
                return
            }

            switch result {
            case .success(let wcpayAccount):
                let account = wcpayAccount.toPaymentGatewayAccount(siteID: siteID)
                self.upsertStoredAccountInBackground(readonlyAccount: account) {
                    onCompletion(.success(()))
                }
            case .failure(let error):
                self.deleteStaleAccount(siteID: siteID, gatewayID: WCPayAccount.gatewayID) {
                    onCompletion(.failure(error))
                }
            }
        }
    }

    func loadStripeAccount(siteID: Int64, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        stripeRemote.loadAccount(for: siteID) { [weak self] result in
            guard let self else {
                return
            }

            switch result {
            case .success(let stripeAccount):
                let account = stripeAccount.toPaymentGatewayAccount(siteID: siteID)
                self.upsertStoredAccountInBackground(readonlyAccount: account) {
                    onCompletion(.success(()))
                }
            case .failure(let error):
                self.deleteStaleAccount(siteID: siteID, gatewayID: StripeAccount.gatewayID) {
                    onCompletion(.failure(error))
                }
            }
        }
    }

    /// Submits order to the site for server-side processing.
    func captureOrderPaymentOnSite(siteID: Int64,
                                   orderID: Int64,
                                   paymentIntent: PaymentIntent) -> AnyPublisher<Result<Void, Error>, Never> {
        let captureOrderPaymentPublisher: AnyPublisher<Result<RemotePaymentIntent, Error>, Never>
        switch usingBackend {
        case .wcPay:
            captureOrderPaymentPublisher = remote.captureOrderPayment(for: siteID, orderID: orderID, paymentIntentID: paymentIntent.id)
        case .stripe:
            captureOrderPaymentPublisher = stripeRemote.captureOrderPayment(for: siteID, orderID: orderID, paymentIntentID: paymentIntent.id)
        }
        return captureOrderPaymentPublisher
            .map { result in
                switch result {
                case .success(let intent):
                    guard intent.status == .succeeded else {
                        DDLogDebug("Unexpected payment intent status \(intent.status) after attempting capture")
                        return .failure(ServerSidePaymentCaptureError.paymentIntentNotSuccessful)
                    }
                    return .success(())
                case .failure(let error):
                    let error = PaymentsError(underlyingError: error)
                    return .failure(ServerSidePaymentCaptureError.paymentGateway(error: error))
                }
            }
            .eraseToAnyPublisher()
    }

    /// Prepares a WCPay terminal payment before the Terminal SDK confirms a collected payment intent.
    func prepareTerminalPayment(siteID: Int64,
                                orderID: Int64,
                                paymentIntent: PaymentIntent,
                                countryCode: CountryCode,
                                terminalPaymentPreparationEnabled: Bool) -> AnyPublisher<Void, Error> {
        guard usingBackend == .wcPay,
              terminalPaymentPreparationEnabled,
              paymentIntent.requiresTerminalPaymentPreparation(countryCode: countryCode) else {
            return Just(())
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        return remote.prepareTerminalPayment(for: siteID, orderID: orderID, paymentIntentID: paymentIntent.id)
            .tryMap { result in
                switch result {
                case .success:
                    return ()
                case .failure(let error):
                    let error = PaymentsError(underlyingError: error)
                    throw ServerSidePaymentCaptureError.terminalPaymentPreparation(error: error)
                }
            }
            .eraseToAnyPublisher()
    }

    func fetchCharge(siteID: Int64, chargeID: String, completion: @escaping (Result<WCPayCharge, Error>) -> Void) {
        switch usingBackend {
        case .wcPay:
            remote.fetchCharge(for: siteID, chargeID: chargeID) { result in
                switch result {
                case .success(let charge):
                    self.upsertCharge(readonlyCharge: charge) {
                        completion(.success(charge))
                    }
                case .failure(let error):
                    if case .noSuchChargeError = PaymentsError(underlyingError: error) {
                        self.deleteCharge(siteID: siteID, chargeID: chargeID) {
                            completion(.failure(error))
                        }
                    } else {
                        completion(.failure(error))
                    }
                }
            }
        case .stripe:
            break /// not implemented
        }
    }
}

private extension PaymentIntent {
    func requiresTerminalPaymentPreparation(countryCode: CountryCode) -> Bool {
        switch paymentMethod() {
        case .interacPresent:
            return true
        case .cardPresent(let details):
            return countryCode == .AU && details.canProcessAsEftposAu
        default:
            return false
        }
    }
}

private extension CardPresentTransactionDetails {
    var canProcessAsEftposAu: Bool {
        brand == .eftposAu || availableNetworks?.contains(.eftposAu) == true
    }
}

// MARK: Storage Methods
private extension CardPresentPaymentStore {
    func upsertStoredAccountInBackground(readonlyAccount: PaymentGatewayAccount, onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ [weak self] storage in
            guard let self else {
                return
            }
            /// Delete any account present. There can be only one.
            deleteStaleAccount(siteID: readonlyAccount.siteID, gatewayID: readonlyAccount.gatewayID, in: storage)

            let storageAccount = storage.insertNewObject(ofType: Storage.PaymentGatewayAccount.self)
            storageAccount.update(with: readonlyAccount)
        }, completion: onCompletion, on: .main)
    }

    func deleteStaleAccount(siteID: Int64, gatewayID: String, onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ [weak self] storage in
            self?.deleteStaleAccount(siteID: siteID, gatewayID: gatewayID, in: storage)
        }, completion: onCompletion, on: .main)
    }

    func deleteStaleAccount(siteID: Int64, gatewayID: String, in storage: StorageType) {
        guard let storageAccount = storage.loadPaymentGatewayAccount(siteID: siteID, gatewayID: gatewayID) else {
            return
        }
        storage.deleteObject(storageAccount)
    }

    func upsertCharge(readonlyCharge: WCPayCharge, onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ [weak self] storage in
            guard let self else { return }
            let storageWCPayCharge = existingOrNewWCPayCharge(siteID: readonlyCharge.siteID, chargeID: readonlyCharge.id, in: storage)

            switch readonlyCharge.paymentMethodDetails {
            case .cardPresent(let details), .interacPresent(let details):
                upsertCardPresentDetails(details, for: storageWCPayCharge, in: storage)
            case .card(let details):
                upsertCardDetails(details, for: storageWCPayCharge, in: storage)
            case .unknown:
                storageWCPayCharge.cardDetails = nil
                storageWCPayCharge.cardPresentDetails = nil
            }

            storageWCPayCharge.update(with: readonlyCharge)
        }, completion: onCompletion, on: .main)
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

    func deleteCharge(siteID: Int64, chargeID: String, onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ storage in
            guard let charge = storage.loadWCPayCharge(siteID: siteID, chargeID: chargeID) else {
                return
            }

            storage.deleteObject(charge)
        }, completion: onCompletion, on: .main)
    }
}

public enum ServerSidePaymentCaptureError: Error, LocalizedError {
    case paymentIntentNotSuccessful
    case paymentGateway(error: PaymentsError)
    case terminalPaymentPreparation(error: PaymentsError)

    public var errorDescription: String? {
        switch self {
        case .paymentIntentNotSuccessful:
            return "Payment intent not successful"
        case .paymentGateway(error: let error):
            return error.localizedDescription
        case .terminalPaymentPreparation(error: let error):
            return error.localizedDescription
        }
    }
}

//periphery:ignore - logging this error detail in WooCommerce is useful, if it ever happens. It's part of the public API here.
public enum CardPresentPaymentStoreError: Error {
    case unknownErrorFetchingAccounts
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
