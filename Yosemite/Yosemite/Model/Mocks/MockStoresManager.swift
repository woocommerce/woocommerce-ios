import Combine
import Observables
import Storage

public class MockStoresManager: StoresManager {

    /// An object graph containing all the mocked data
    ///
    private let objectGraph: MockObjectGraph

    /// The Core Data Stack
    ///
    private let storageManager: StorageManagerType

    /// A derived stack we use for inserting data
    ///
    private lazy var derivedStorage = storageManager.newDerivedStorage()

    /// All of our action handlers
    private let appSettingsActionHandler: MockAppSettingsActionHandler
    private let availabilityActionHandler: MockAvailabilityActionHandler
    private let notificationActionHandler: MockNotificationActionHandler
    private let notificationCountActionHandler: MockNotificationCountActionHandler
    private let orderActionHandler: MockOrderActionHandler
    private let orderStatusActionHandler: MockOrderStatusActionHandler
    private let orderNoteActionHandler: MockOrderNoteActionHandler
    private let productActionHandler: MockProductActionHandler
    private let productReviewActionHandler: MockProductReviewActionHandler
    private let productVariationActionHandler: MockProductVariationActionHandler
    private let refundActionHandler: MockRefundActionHandler
    private let settingActionHandler: MockSettingActionHandler
    private let shipmentActionHandler: MockShipmentActionHandler
    private let shippingLabelActionHandler: MockShippingLabelActionHandler
    private let statsV4ActionHandler: MockStatsActionV4Handler


    init(objectGraph: MockObjectGraph, storageManager: StorageManagerType) {
        self.objectGraph = objectGraph
        self.storageManager = storageManager

        orderActionHandler = MockOrderActionHandler(objectGraph: objectGraph, storageManager: storageManager)
        notificationCountActionHandler = MockNotificationCountActionHandler(objectGraph: objectGraph, storageManager: storageManager)
        appSettingsActionHandler = MockAppSettingsActionHandler(objectGraph: objectGraph, storageManager: storageManager)
        statsV4ActionHandler = MockStatsActionV4Handler(objectGraph: objectGraph, storageManager: storageManager)
        availabilityActionHandler = MockAvailabilityActionHandler(objectGraph: objectGraph, storageManager: storageManager)
        settingActionHandler = MockSettingActionHandler(objectGraph: objectGraph, storageManager: storageManager)
        orderStatusActionHandler = MockOrderStatusActionHandler(objectGraph: objectGraph, storageManager: storageManager)
        orderNoteActionHandler = MockOrderNoteActionHandler(objectGraph: objectGraph, storageManager: storageManager)
        productActionHandler = MockProductActionHandler(objectGraph: objectGraph, storageManager: storageManager)
        productVariationActionHandler = MockProductVariationActionHandler(objectGraph: objectGraph, storageManager: storageManager)
        refundActionHandler = MockRefundActionHandler(objectGraph: objectGraph, storageManager: storageManager)
        shippingLabelActionHandler = MockShippingLabelActionHandler(objectGraph: objectGraph, storageManager: storageManager)
        shipmentActionHandler = MockShipmentActionHandler(objectGraph: objectGraph, storageManager: storageManager)
        productReviewActionHandler = MockProductReviewActionHandler(objectGraph: objectGraph, storageManager: storageManager)
        notificationActionHandler = MockNotificationActionHandler(objectGraph: objectGraph, storageManager: storageManager)
    }

    /// Accessor for whether the user is logged in (spoiler: they always will be when mocking)
    ///
    public var isLoggedInPublisher: AnyPublisher<Bool, Never> {
        isLoggedInSubject.eraseToAnyPublisher()
    }

    /// The backing object for `isLoggedIn`
    ///
    private let isLoggedInSubject = CurrentValueSubject<Bool, Never>(true)

    /// A mock session manager that aligns with our mock object graph
    ///
    private(set)
    lazy public var sessionManager: SessionManagerProtocol = {
        return MockSessionManager(objectGraph: objectGraph)
    }()

    /// The current site ID
    ///
    public var siteID: Observable<Int64?> {
        sessionManager.siteID
    }

    public func dispatch(_ action: Action) {
        // We can choose which actions we want to handle and how we respond.
        switch action {
            case let action as OrderAction:
                orderActionHandler.handle(action: action)
            case let action as NotificationCountAction:
                notificationCountActionHandler.handle(action: action)
            case let action as AppSettingsAction:
                appSettingsActionHandler.handle(action: action)
            case let action as StatsActionV4:
                statsV4ActionHandler.handle(action: action)
            case let action as AvailabilityAction:
                availabilityActionHandler.handle(action: action)
            case let action as SettingAction:
                settingActionHandler.handle(action: action)
            case let action as OrderStatusAction:
                orderStatusActionHandler.handle(action: action)
            case let action as OrderNoteAction:
                orderNoteActionHandler.handle(action: action)
            case let action as ProductAction:
                productActionHandler.handle(action: action)
            case let action as ProductVariationAction:
                productVariationActionHandler.handle(action: action)
            case let action as RefundAction:
                refundActionHandler.handle(action: action)
            case let action as ShippingLabelAction:
                shippingLabelActionHandler.handle(action: action)
            case let action as ShipmentAction:
                shipmentActionHandler.handle(action: action)
            case let action as ProductReviewAction:
                productReviewActionHandler.handle(action: action)
            case let action as NotificationAction:
                notificationActionHandler.handle(action: action)
            default:
                fatalError("Unable to handle action: \(action.identifier) \(String(describing: action))")
        }
    }

    public func dispatch(_ actions: [Action]) {
        actions.forEach(dispatch)
    }

    public func removeDefaultStore() {
        /// Does nothing
    }

    @discardableResult
    public func authenticate(credentials: Credentials) -> StoresManager {
        return self
    }

    @discardableResult
    public func deauthenticate() -> StoresManager {
        return self
    }

    @discardableResult
    public func synchronizeEntities(onCompletion: (() -> Void)?) -> StoresManager {
        onCompletion?()
        return self
    }

    public func updateDefaultStore(storeID: Int64) {
        // Does nothing
    }

    public var isAuthenticated: Bool {
        true
    }

    public var needsDefaultStore: Bool {
        sessionManager.defaultStoreID == nil
    }

    public var needsDefaultStorePublisher: AnyPublisher<Bool, Never> {
        sessionManager.defaultStoreIDPublisher
            .map { $0 == nil }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
