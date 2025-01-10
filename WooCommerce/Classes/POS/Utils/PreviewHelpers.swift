#if DEBUG

import Foundation
import protocol Yosemite.PointOfSaleItemServiceProtocol
import enum Yosemite.POSItem
import struct Yosemite.POSSimpleProduct
import protocol Yosemite.POSOrderableItem
import protocol Yosemite.OrderSyncProductTypeProtocol
import struct Yosemite.OrderSyncProductInput
import enum Yosemite.ProductType
import struct Yosemite.PagedItems
import struct Yosemite.POSVariableParentProduct
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
    func providePointOfSaleItems(pageNumber: Int) async throws -> PagedItems<POSItem> {
        .init(items: [], hasMorePages: true)
    }

    func providePointOfSaleVariationItems(for parentProduct: POSVariableParentProduct, pageNumber: Int) async throws -> PagedItems<POSItem> {
        .init(items: mockVariationItems, hasMorePages: true)
    }

    func providePointOfSaleItems() -> [POSItem] {
        return mockItems
    }

    func providePointOfSaleItem() -> POSOrderableItem {
        POSProductPreview(id: UUID(),
                          name: "Product 1",
                          formattedPrice: "$1.00")
    }
}

final class PointOfSalePreviewItemsController: PointOfSaleItemsControllerProtocol {
    @Published var itemsViewState: ItemsViewState = ItemsViewState(containerState: .loading,
                                                                   itemsStack: ItemsStackState(root: .loading([]),
                                                                                               itemStates: [:]))
    var itemsViewStatePublisher: any Publisher<ItemsViewState, Never> { $itemsViewState }

    func loadInitialItems() async {
        itemsViewState = ItemsViewState(containerState: .content, itemsStack: ItemsStackState(root: .loaded(mockItems, hasMoreItems: true),
                                                                                              itemStates: [:]))
    }

    func loadNextItems() async {
        itemsViewState = ItemsViewState(containerState: .content, itemsStack: ItemsStackState(root: .loading(mockItems),
                                                                                              itemStates: [:]))
    }

    func reload() async {
        itemsViewState = ItemsViewState(containerState: .content, itemsStack: ItemsStackState(root: .loaded([], hasMoreItems: false),
                                                                                              itemStates: [:]))
    }

    func loadInitialChildItems(for parent: POSItem) async {
        itemsViewState = ItemsViewState(
            containerState: .content,
            itemsStack: ItemsStackState(
                root: .loading(mockItems),
                itemStates: [parent: .loaded(mockVariationItems, hasMoreItems: true)]
            )
        )
    }
}

private var mockItems: [POSItem] {
    return [
        .simpleProduct(POSSimpleProduct(id: UUID(), name: "Product 1", formattedPrice: "$1.00", productID: 1, price: "1.00")),
        .simpleProduct(POSSimpleProduct(id: UUID(), name: "Product 2", formattedPrice: "$2.00", productID: 2, price: "2.00")),
        .simpleProduct(POSSimpleProduct(id: UUID(), name: "Product 3", formattedPrice: "$3.00", productID: 3, price: "3.00")),
        .variableParentProduct(
            .init(
                id: .init(),
                name: "Variable product 1",
                productImageSource: nil,
                productID: 5
            )
        ),
        .simpleProduct(POSSimpleProduct(id: UUID(), name: "Product 4", formattedPrice: "$4.00", productID: 4, price: "4.00"))
    ]
}

private var mockVariationItems: [POSItem] {
    [
        .variation(.init(id: UUID(),
                         name: "Variation 1",
                         formattedPrice: "$1.00",
                         price: "1.00",
                         productID: 134,
                         variationID: 256)),
        .variation(.init(id: UUID(),
                         name: "Variation 2",
                         formattedPrice: "$2.00",
                         price: "2.00",
                         productID: 134,
                         variationID: 256)),
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
