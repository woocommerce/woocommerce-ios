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
        case .initialize(let siteID):
            initialize(siteID: siteID)
        case .startCardReaderDiscovery(let completion):
            startCardReaderDiscovery(completion: completion)
        case .connect(let reader, let completion):
            connect(reader: reader, onCompletion: completion)
        }
    }
}


// MARK: - Services
//
private extension CardPresentPaymentStore {
    func initialize(siteID: Int64) {
        remote.loadConnectionToken(for: siteID) { [weak self] (token, error) in
            print("======== load connection token completed")
            print("token ", token?.token)
            print("error ", error)
            print("//////// load connection token completed")
        }
    }

    func startCardReaderDiscovery(completion: @escaping (_ readers: [CardReader]) -> Void) {
        cardReaderService.start()

        // Over simplification. This is the point where we would receive
        // new data via the CardReaderService's stream of discovered readers
        // In here, we should redirect that data to Storage and also up to the UI.
        // For now we are sending the data up to the UI directly
        cardReaderService.discoveredReaders.sink { readers in
            completion(readers)
        }.store(in: &cancellables)
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
}
