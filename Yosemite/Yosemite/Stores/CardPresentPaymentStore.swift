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

    private let remote: WCPayRemote

    private var cancellables: Set<AnyCancellable> = []

    /// We need to be able to cancel the process of collecting a payment.
    private var paymentCancellable: AnyCancellable? = nil

    public init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, cardReaderService: CardReaderService) {
        self.cardReaderService = cardReaderService
        self.remote = WCPayRemote(network: network)
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
        }
    }
}


// MARK: - Services
//
private extension CardPresentPaymentStore {
    func startCardReaderDiscovery(siteID: Int64, onReaderDiscovered: @escaping (_ readers: [CardReader]) -> Void, onError: @escaping (Error) -> Void) {
        do {
            try cardReaderService.start(WCPayTokenProvider(siteID: siteID, remote: self.remote))
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
                    let supportedReaders = readers.filter({$0.readerType == .chipper || $0.readerType == .stripeM2 || $0.readerType == .other})
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


/// Implementation of the CardReaderNetworkingAdapter
/// that fetches a token using WCPayRemote
private final class WCPayTokenProvider: CardReaderConfigProvider {
    private let siteID: Int64
    private let remote: WCPayRemote

    init(siteID: Int64, remote: WCPayRemote) {
        self.siteID = siteID
        self.remote = remote
    }

    func fetchToken(completion: @escaping(Result<String, Error>) -> Void) {
        remote.loadConnectionToken(for: siteID) { result in
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

    func fetchDefaultLocationID(completion: @escaping(Result<String, Error>) -> Void) {
        remote.loadDefaultReaderLocation(for: siteID) { result in
            switch result {
            case .success(let wcpayReaderLocation):
                let readerLocation = wcpayReaderLocation.toReaderLocation(siteID: self.siteID)
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
