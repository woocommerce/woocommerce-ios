import Yosemite

/// FIXME We're not supposed to be importing Networking in WooCommerce.
import struct Networking.ScreenshotObjects

/// This should most probably be in `Yosemite` so it can access business logic units like
/// `OrdersUpsertUseCase`.
final class ScreenshotsStoresManager: StoresManager {

    /// I think we should inject this. This is a prototype. :D
    private let storageManager = ServiceLocator.storageManager

    private lazy var derivedStorage = storageManager.newDerivedStorage()

    private let objectGraph = ScreenshotObjects()

    var isLoggedIn: Observable<Bool> {
        isLoggedInSubject
    }
    private let isLoggedInSubject = BehaviorSubject<Bool>(true)

    private(set) lazy var sessionManager: SessionManager = {
        // TODO Probably best to instantiate our own.
        let sessionManager = SessionManager.standard
        sessionManager.defaultStoreID = self.objectGraph.defaultSite.siteID
        return sessionManager
    }()

    var siteID: Observable<Int64?> {
        sessionManager.siteID
    }

    func dispatch(_ action: Action) {
        // We can choose which actions we want to handle and how we respond.
        switch action {
        case let orderAction as OrderAction:
            switch orderAction {
            case .fetchFilteredAndAllOrders(_, _, _, _, _, let onCompletion):
                saveOrders(onCompletion: onCompletion)
            default:
                print(action)
            }
        default:
            print(action)
        }
    }

    func dispatch(_ actions: [Action]) {
        print(actions)
    }

    func removeDefaultStore() {

    }

    @discardableResult
    func authenticate(credentials: Credentials) -> StoresManager {
        return self
    }

    @discardableResult
    func deauthenticate() -> StoresManager {
        return self
    }

    @discardableResult
    func synchronizeEntities(onCompletion: (() -> Void)?) -> StoresManager {
        onCompletion?()
        return self
    }

    func updateDefaultStore(storeID: Int64) {

    }

    var isAuthenticated: Bool {
        true
    }

    var needsDefaultStore: Bool {
        sessionManager.defaultStoreID == nil
    }
}

private extension ScreenshotsStoresManager {

    func saveOrders(onCompletion: @escaping (Error?) -> ()) {
        derivedStorage.perform {
            let storageOrders: [StorageOrder] = self.objectGraph.orders.map { order in
                let storageOrder = self.derivedStorage.insertNewObject(ofType: StorageOrder.self)
                storageOrder.update(with: order)
                return storageOrder
            }

            // LOL we should hide the error instead of crashing
            try! self.derivedStorage.obtainPermanentIDs(for: storageOrders)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async {
                onCompletion(nil)
            }
        }
    }
}
