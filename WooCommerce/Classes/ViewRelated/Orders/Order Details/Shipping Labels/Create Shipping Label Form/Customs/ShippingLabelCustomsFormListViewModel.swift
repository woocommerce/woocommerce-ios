import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// View model for ShippingLabelsCustomsFormList
///
final class ShippingLabelCustomsFormListViewModel: ObservableObject {

    /// Associated order of the shipping label.
    ///
    private let order: Order

    /// Input customs forms of the shipping label if added initially.
    ///
    private let customsForms: [ShippingLabelCustomsForm]

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
