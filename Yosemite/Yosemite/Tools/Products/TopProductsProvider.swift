//
//  TopProductsProvider.swift
//  Yosemite
//
//  Created by César Vargas Casaseca on 20/4/23.
//  Copyright © 2023 Automattic. All rights reserved.
//

import Foundation
import Storage

public final class TopProductsProvider {
    private let storageManager: StorageManagerType
    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

    public init(storageManager: StorageManagerType) {
        self.storageManager = storageManager
    }

    public func provideTopProductsFromCachedOrders(siteID: Int64, limitPerType: Int) -> ([Int64], [Int64]) {
        let popularProductsIds = Array(popularProductsIds(from: siteID).prefix(limitPerType))
        let lastSoldProductsIds = Array(lastSoldProductIds(from: siteID)
            .filter { !popularProductsIds.contains($0) }
            .prefix(limitPerType))

        debugPrint("popular \(popularProductsIds) last sold \(lastSoldProductsIds)")

        return (popularProductsIds, lastSoldProductsIds)

    }

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
