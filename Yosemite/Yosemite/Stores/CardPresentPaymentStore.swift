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
        case .startCardReaderDiscovery(let siteID, let completion):
            startCardReaderDiscovery(siteID: siteID, completion: completion)
        case .cancelCardReaderDiscovery(let completion):
            cancelCardReaderDiscovery(completion: completion)
        case .connect(let reader, let completion):
            connect(reader: reader, onCompletion: completion)
        case .collectPayment(let siteID, let orderID, let parameters, let completion):
            collectPayment(siteID: siteID,
                           orderID: orderID,
                           parameters: parameters,
                           onCompletion: completion)
        }
    }
}


// MARK: - Services
//
private extension CardPresentPaymentStore {
    func startCardReaderDiscovery(siteID: Int64, completion: @escaping (_ readers: [CardReader]) -> Void) {
        cardReaderService.start(WCPayTokenProvider(siteID: siteID, remote: self.remote))

        // Over simplification. This is the point where we would receive
        // new data via the CardReaderService's stream of discovered readers
        // In here, we should redirect that data to Storage and also up to the UI.
        // For now we are sending the data up to the UI directly
        print("**** Store. starting discovery*")
        cardReaderService.discoveredReaders.sink { readers in
            completion(readers)
        }.store(in: &cancellables)
    }

    func cancelCardReaderDiscovery(completion: @escaping (CardReaderServiceDiscoveryStatus) -> Void) {
        print("**** Store. cancelling discovery*")
        cardReaderService.discoveryStatus.sink { status in
            print("///// status received ", status)
            completion(status)
        }.store(in: &cancellables)

        cardReaderService.cancelDiscovery()
    }

    func connect(reader: Yosemite.CardReader, onCompletion: @escaping (Result<[Yosemite.CardReader], Error>) -> Void) {
        // We tiptoe around this for now. We will get into error handling later:
        // https://github.com/woocommerce/woocommerce-ios/issues/3734
        // https://github.com/woocommerce/woocommerce-ios/issues/3741
        cardReaderService.connect(reader).sink(receiveCompletion: { error in
        }, receiveValue: { (result) in
        }).store(in: &cancellables)

        // Dispatch completion block everytime the service published a new
        // collection of connected readers
        cardReaderService.connectedReaders.sink { connectedHardwareReaders in
            onCompletion(.success(connectedHardwareReaders))
        }.store(in: &cancellables)
    }

    func collectPayment(siteID: Int64, orderID: Int64, parameters: PaymentParameters, onCompletion: @escaping (Result<Void, Error>) -> Void) {

        cardReaderService.createPaymentIntent(parameters)
            .flatMap {
                self.cardReaderService.collectPaymentMethod()
            }.flatMap {
                self.cardReaderService.processPayment()
            }.sink { error in
            switch error {
            case .failure(let error):
                onCompletion(.failure(error))
            case .finished:
                onCompletion(.success(()))
            }
        } receiveValue: { intent in
            print("==== Yosemite log for testing. Payment intent after processing payment")
            print(intent)
            print("//// payment intent processed ")
            // TODO. Initiate final step. Update order. Submit intent id to backend.
            // Deferred to https://github.com/woocommerce/woocommerce-ios/issues/3825
            onCompletion(.success(()))
        }.store(in: &cancellables)
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

    func fetchToken(completion: @escaping(String?, Error?) -> Void) {
        remote.loadConnectionToken(for: siteID) { token, error in
            completion(token?.token, error)
        }
    }
}
