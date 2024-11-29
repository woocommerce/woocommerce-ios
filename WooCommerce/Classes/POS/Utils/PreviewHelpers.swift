#if DEBUG

import Foundation
import protocol Yosemite.PointOfSaleItemServiceProtocol
import protocol Yosemite.POSDisplayableItem
import typealias Yosemite.POSOrderableItem
import protocol Yosemite.OrderSyncProductTypeProtocol
import struct Yosemite.OrderSyncProductInput
import enum Yosemite.ProductType
import struct Yosemite.ProductBundleItem
import struct Yosemite.OrderItem
import Combine

// MARK: - PreviewProvider helpers
//
struct POSProductPreview: POSOrderableItem, Equatable {
    let id: UUID
    let name: String
    let formattedPrice: String
    var productImageSource: String?

    struct POSProductPreviewType: OrderSyncProductTypeProtocol {
        var price: String = ""
        var productID: Int64 = 0
        var productType: Yosemite.ProductType = .simple
        var bundledItems: [Yosemite.ProductBundleItem] = []
    }

    func toOrderSyncProductInput(quantity: Decimal) -> OrderSyncProductInput {
        OrderSyncProductInput(product: .product(POSProductPreviewType()), quantity: 1)
    }

    func matches(orderItem: OrderItem) -> Bool {
        return false
    }
}

final class PointOfSalePreviewItemService: PointOfSaleItemServiceProtocol {
    func providePointOfSaleItems(pageNumber: Int) async throws -> [any POSDisplayableItem] {
        []
    }

    func providePointOfSaleItems() -> [any POSDisplayableItem] {
        return mockItems
    }

    func providePointOfSaleItem() -> any POSOrderableItem {
        POSProductPreview(id: UUID(),
                          name: "Product 1",
                          formattedPrice: "$1.00")
    }
}

final class PointOfSalePreviewItemsController: PointOfSaleItemsControllerProtocol {
    @Published var itemListState: ItemListState = .initialLoading
    var itemListStatePublisher: any Publisher<ItemListState, Never> { $itemListState }

    var allItems: [any POSDisplayableItem] = []

    func loadInitialItems() async {
        itemListState = .loaded(mockItems)
    }

    func loadNextItems() async {
        itemListState = .loading(mockItems)
    }

    func reload() async {
        itemListState = .loaded([])
    }
}

private var mockItems: [any POSDisplayableItem] {
    return [
        POSProductPreview(id: UUID(), name: "Product 1", formattedPrice: "$1.00"),
        POSProductPreview(id: UUID(), name: "Product 2", formattedPrice: "$2.00"),
        POSProductPreview(id: UUID(), name: "Product 3", formattedPrice: "$3.00"),
        POSProductPreview(id: UUID(), name: "Product 4", formattedPrice: "$4.00")
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
