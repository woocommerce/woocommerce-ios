#if DEBUG

import Foundation
import protocol Yosemite.PointOfSaleItemServiceProtocol
import enum Yosemite.POSItem
import struct Yosemite.POSProduct
import protocol Yosemite.OrderSyncProductTypeProtocol
import struct Yosemite.OrderSyncProductInput
import enum Yosemite.ProductType
import struct Yosemite.ProductBundleItem
import struct Yosemite.OrderItem
import struct Yosemite.POSParentProduct
import Combine

// MARK: - PreviewProvider helpers
//
final class PointOfSalePreviewItemService: PointOfSaleItemServiceProtocol {
    func providePointOfSaleItems(pageNumber: Int) async throws -> [POSItem] {
        []
    }

    func providePointOfSaleItems() -> [POSItem] {
        return mockItems
    }

    func providePointOfSaleItem() -> POSItem {
        .product(POSProduct(id: UUID(),
                            name: "Product 1",
                            formattedPrice: "$1.00",
                            productID: 0,
                            price: "1.00"))
    }
}

final class PointOfSalePreviewItemsController: PointOfSaleItemsControllerProtocol {
    @Published var itemsViewState: ItemsViewState = ItemsViewState(
        containerState: .initialLoading,
        itemsStackState: .init(
            rootState: ItemListState(loadState: .loading, items: [], pageInfo: .init(currentPage: 1, hasMorePages: true)),
            itemStates: [:]))
    var itemsViewStatePublisher: any Publisher<ItemsViewState, Never> { $itemsViewState }

    func loadInitialItems() async {
    }

    func loadNextItems(parent: POSItem?) async {
    }

    func reload(parent: POSItem?) async {
    }

    func childState(for parent: POSItem) -> ItemListState {
        return ItemListState(loadState: .loading, items: [], pageInfo: .init(currentPage: 1, hasMorePages: true))
    }
}

private var mockItems: [POSItem] {
    return [
        .product(POSProduct(id: UUID(), name: "Product 1", formattedPrice: "$1.00", productID: 1, price: "1.00")),
        .product(POSProduct(id: UUID(), name: "Product 2", formattedPrice: "$2.00", productID: 2, price: "2.00")),
        .product(POSProduct(id: UUID(), name: "Product 3", formattedPrice: "$3.00", productID: 3, price: "3.00")),
        .product(POSProduct(id: UUID(), name: "Product 4", formattedPrice: "$4.00", productID: 4, price: "4.00"))
    ]
}

final class POSConnectivityObserverPreview: ConnectivityObserver {
    @Published private(set) var currentStatus: ConnectivityStatus = .unknown
    var statusPublisher: AnyPublisher<ConnectivityStatus, Never> {
        $currentStatus.eraseToAnyPublisher()
    }
    func startObserving() {}

    func stopObserving() {}
}

#endif
