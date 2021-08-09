import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// View model for ShippingLabelsCustomsFormList
///
final class ShippingLabelCustomsFormListViewModel: ObservableObject {
    /// Whether packages multiple packages are found.
    ///
    lazy var multiplePackagesDetected: Bool = {
        customsForms.count > 1
    }()

    /// References of input view models.
    ///
    private(set) var inputViewModels: [ShippingLabelCustomsFormInputViewModel] = []

    /// Input customs forms of the shipping label if added initially.
    ///
    @Published var customsForms: [ShippingLabelCustomsForm] {
        didSet {
            inputViewModels = customsForms.map { .init(customsForm: $0) }
        }
    }

    /// Associated order of the shipping label.
    ///
    private let order: Order

    /// Stores to sync data of products and variations.
    ///
    private let stores: StoresManager

    /// Storage to fetch products and variations.
    ///
    private let storageManager: StorageManagerType

    init(order: Order,
         customsForms: [ShippingLabelCustomsForm],
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.order = order
        self.customsForms = customsForms
        self.stores = stores
        self.storageManager = storageManager
    }
}
