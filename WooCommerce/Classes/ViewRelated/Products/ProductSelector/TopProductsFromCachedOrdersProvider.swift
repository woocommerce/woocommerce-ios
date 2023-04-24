import Foundation
import Yosemite
import Storage

/// Encapsulates the ids of those products that were most or last sold among the cached orders
///
struct ProductSelectorTopProducts: Equatable {
    let popularProductsIds: [Int64]
    let lastSoldProductsIds: [Int64]

    static var empty: ProductSelectorTopProducts {
        ProductSelectorTopProducts(popularProductsIds: [],
                                    lastSoldProductsIds: [])
    }
}

protocol ProductSelectorTopProductsProviderProtocol {
    func provideTopProducts(siteID: Int64) -> ProductSelectorTopProducts
}

/// Provides the ids of those products that were most or last sold among the cached orders
///
final class TopProductsFromCachedOrdersProvider: ProductSelectorTopProductsProviderProtocol {
    private let storageManager: StorageManagerType
    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.viewStorage
    }()

    init(storageManager: StorageManagerType) {
        self.storageManager = storageManager
    }

    func provideTopProducts(siteID: Int64) -> ProductSelectorTopProducts {
        ProductSelectorTopProducts(popularProductsIds: retrievePopularProductsIds(from: siteID),
                                           lastSoldProductsIds: retrieveLastSoldProductIds(from: siteID))
    }
}

private extension TopProductsFromCachedOrdersProvider {
    func retrievePopularProductsIds(from siteID: Int64) -> [Int64] {
        // Get product ids sorted by occurence
        let completedOrdersItems = retrieveCompletedOrders(from: siteID).flatMap { $0.items }
        let productIDCountDictionary = completedOrdersItems.reduce(into: [:]) { counts, orderItem in counts[orderItem.productID, default: 0] += 1 }

        return productIDCountDictionary
            .sorted {
                // if the count is the same let's sort it by product id just to avoid randomly sorted sequences
                if $0.value == $1.value {
                    return $0.key > $1.key
                }

                return $0.value > $1.value

            }
            .map { $0.key }
            .uniqued()
    }

    func retrieveLastSoldProductIds(from siteID: Int64) -> [Int64] {
        retrieveCompletedOrders(from: siteID)
            .flatMap { $0.items }
            .map { $0.productID }
            .uniqued()
    }

    func retrieveCompletedOrders(from siteID: Int64) -> [Yosemite.Order] {
        let completedStorageOrders = sharedDerivedStorage.allObjects(ofType: StorageOrder.self,
                                                      matching: completedOrdersPredicate(from: siteID),
                                                      sortedBy: [NSSortDescriptor(key: #keyPath(StorageOrder.datePaid), ascending: false)])

        return completedStorageOrders.map { $0.toReadOnly() }
    }

    func completedOrdersPredicate(from siteID: Int64) -> NSPredicate {
        let completedOrderPredicate = NSPredicate(format: "statusKey ==[c] %@", OrderStatusEnum.completed.rawValue)
        let sitePredicate = NSPredicate(format: "siteID == %lld", siteID)

        return NSCompoundPredicate(andPredicateWithSubpredicates: [completedOrderPredicate, sitePredicate])
    }
}
