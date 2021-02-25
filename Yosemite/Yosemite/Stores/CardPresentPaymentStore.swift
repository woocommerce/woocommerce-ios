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

    private var cancellable: AnyCancellable?

    // To be removed when we implement the Storage Layer properly:
    // https://github.com/woocommerce/woocommerce-ios/issues/3739
    private var hardwareReadersCache: [Hardware.CardReader] = []

    public init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, cardReaderService: CardReaderService) {
        self.cardReaderService = cardReaderService
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
    func startCardReaderDiscovery(completion: @escaping (_ readers: [CardReader]) -> Void) {
        cardReaderService.start()

        // Over simplification. This is the point where we would receive
        // new data via the CardReaderService's stream of discovered readers
        // In here, we should redirect that data to Storage and also up to the UI.
        // For now we are sending the data up to the UI after mapping CardReaderService.CardReader
        // to Yosemite.CardReader.
        cancellable = cardReaderService.discoveredReaders.sink { [weak self] readers in

            guard let self = self else {
                return
            }

            self.cacheHardwareReaders(readers)

            let yosemiteReaders = readers.map {
                Yosemite.CardReader(name: $0.name, serialNumber: $0.serial)
            }

            completion(yosemiteReaders)
        }
    }

    func connect(reader: Yosemite.CardReader, onCompletion: @escaping (Result<Yosemite.CardReader, Error>) -> Void) {
        guard let hardwareReader = hardwareReaderMatching(reader) else {
            // Wrong internal state. Return an error
            return
        }

        cancellable = cardReaderService.connect(hardwareReader).sink(receiveCompletion: { error in
            //
            print("===== completion received")
        }, receiveValue: { (result) in
            //
            print("value received === ", result)
        })
    }
}


/// This extension will go away as soon as we start
/// adding support for persistance in Storage.
/// https://github.com/woocommerce/woocommerce-ios/issues/3739
/// For now, we will use it to "fake" a storage layer
/// We could inject a StorageManagerType to implement this
/// but it's probably not worth the effort at this point.
private extension CardPresentPaymentStore {
    func cacheHardwareReaders(_ readers: [Hardware.CardReader]) {
        hardwareReadersCache = readers
    }

    func hardwareReaderMatching(_ reader: Yosemite.CardReader) -> Hardware.CardReader? {
        return hardwareReadersCache.filter {
            $0.id == reader.id
        }.first
    }
}
