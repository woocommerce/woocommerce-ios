import Foundation
import Yosemite
import Storage

/// Encapsulates the ids of those products that were most or last sold among the cached orders
///
struct TopProductsFromCachedOrders: Equatable {
    let popularProductsIds: [Int64]
    let lastSoldProductsIds: [Int64]

    static var empty: TopProductsFromCachedOrders {
        TopProductsFromCachedOrders(popularProductsIds: [],
                                    lastSoldProductsIds: [])
    }
}

protocol TopProductsFromCachedOrdersProviderProtocol {
    func provideTopProductsFromCachedOrders(siteID: Int64) -> TopProductsFromCachedOrders
}

/// Provides the ids of those products that were most or last sold among the cached orders
///
final class TopProductsFromCachedOrdersProvider: TopProductsFromCachedOrdersProviderProtocol {
    private let storageManager: StorageManagerType
    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.viewStorage
    }()

    init(storageManager: StorageManagerType) {
        self.storageManager = storageManager
    }

    func provideTopProductsFromCachedOrders(siteID: Int64) -> TopProductsFromCachedOrders {
        TopProductsFromCachedOrders(popularProductsIds: popularProductsIds(from: siteID),
                                           lastSoldProductsIds: lastSoldProductIds(from: siteID))
    }
}

private extension TopProductsFromCachedOrdersProvider {
    func popularProductsIds(from siteID: Int64) -> [Int64] {
        let completedStorageOrders = sharedDerivedStorage.allObjects(ofType: StorageOrder.self,
                                                      matching: completedOrdersPredicate(from: siteID),
                                                      sortedBy: nil)

        let completedOrders = completedStorageOrders.map { $0.toReadOnly() }

        // Get product ids sorted by occurence
        let completedOrdersItems = completedOrders.flatMap { $0.items }
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

    func lastSoldProductIds(from siteID: Int64) -> [Int64] {
        let completedStorageOrders = sharedDerivedStorage.allObjects(ofType: StorageOrder.self,
                                                      matching: completedOrdersPredicate(from: siteID),
                                                      sortedBy: [NSSortDescriptor(key: #keyPath(StorageOrder.datePaid), ascending: false)])

        let completedOrders = completedStorageOrders.map { $0.toReadOnly() }

        return completedOrders
            .flatMap { $0.items }
            .map { $0.productID }
            .uniqued()
    }

    func completedOrdersPredicate(from siteID: Int64) -> NSPredicate {
        let completedOrderPredicate = NSPredicate(format: "statusKey ==[c] %@", OrderStatusEnum.completed.rawValue)
        let sitePredicate = NSPredicate(format: "siteID == %lld", siteID)

        return NSCompoundPredicate(andPredicateWithSubpredicates: [completedOrderPredicate, sitePredicate])
    }
}
