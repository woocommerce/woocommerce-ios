import Foundation

import protocol Yosemite.POSItem
import protocol Yosemite.POSItemProvider
import protocol WooFoundation.Analytics

protocol PointOfSaleAggregateModelProtocol {
    var orderStage: PointOfSaleOrderStage { get }

    @available(*, deprecated, message: "`allItems` is due for removal, use `itemListState` instead.")
    var allItems: [POSItem] { get }
    var itemListState: ItemListState { get }

    func loadInitialItems() async
    func loadNextItems() async
    func reload() async

    var cart: [CartItem] { get }
    func addToCart(_ item: POSItem)
    func remove(cartItem: CartItem)
    func removeAllItemsFromCart()
    func submitCart()
    func addMoreToCart()
    func startNewCart()
}

class PointOfSaleAggregateModel: ObservableObject, PointOfSaleAggregateModelProtocol {
    @Published private(set) var orderStage: PointOfSaleOrderStage = .building

    @Published private(set) var allItems: [POSItem] = []
    @Published private(set) var itemListState: ItemListState = .initialLoading

    @Published private(set) var cart: [CartItem] = []

    private let itemProvider: POSItemProvider
    private let analytics: Analytics

    private var currentPage: Int = Constants.initialPage

    init(itemProvider: POSItemProvider,
         analytics: Analytics = ServiceLocator.analytics) {
        self.itemProvider = itemProvider
        self.analytics = analytics
    }
}

// MARK: - ItemList
extension PointOfSaleAggregateModel {
    @MainActor
    func loadInitialItems() async {
        itemListState = .initialLoading
        try? await load(pageNumber: Constants.initialPage)
    }

    @MainActor
    func loadNextItems() async {
        do {
            itemListState = .loading(allItems)
            // TODO: Optimize API calls. gh-14186
            // If there are no more pages to fetch, we can avoid the next call.
            let nextPage = currentPage + 1
            try await load(pageNumber: nextPage)
            currentPage = nextPage
        } catch {
            // No need to do anything; this avoids us incorrectly incrementing currentPage.
        }
    }

    @MainActor
    func reload() async {
        allItems.removeAll()
        currentPage = Constants.initialPage
        itemListState = .loading(allItems)
        try? await load(pageNumber: currentPage)
    }

    @MainActor
    private func load(pageNumber: Int) async throws {
        do {
            try await fetchItems(pageNumber: pageNumber)
        } catch {
            itemListState = .error(PointOfSaleErrorState.errorOnLoadingProducts())
            throw error
        }
    }

    @MainActor
    private func fetchItems(pageNumber: Int) async throws {
        let newItems = try await itemProvider.providePointOfSaleItems(pageNumber: pageNumber)
        let uniqueNewItems = newItems.filter { newItem in
            !allItems.contains(where: { $0.productID == newItem.productID })
        }

        allItems.append(contentsOf: uniqueNewItems)

        if allItems.count == 0 {
            itemListState = .empty
        } else {
            itemListState = .loaded(allItems)
        }
    }
}

// MARK: - Cart

extension PointOfSaleAggregateModel {
    func addToCart(_ item: POSItem) {
        cart.insert(CartItem(id: UUID(), item: item, quantity: 1), at: 0)
        Task { @MainActor in
            analytics.track(.pointOfSaleAddItemToCart)
        }
    }

    func remove(cartItem: CartItem) {
        cart.removeAll(where: { $0.id == cartItem.id } )
    }

    func removeAllItemsFromCart() {
        cart.removeAll()
    }

    func submitCart() {
        orderStage = .finalizing
    }

    func addMoreToCart() {
        orderStage = .building
    }

    func startNewCart() {
        removeAllItemsFromCart()
        orderStage = .building
    }
}

private extension PointOfSaleAggregateModel {
    enum Constants {
        static let initialPage: Int = 1
    }
}

struct PointOfSaleErrorState: Equatable {
    let title: String
    let subtitle: String
    let buttonText: String

    static func errorOnLoadingProducts() -> Self {
        PointOfSaleErrorState(title: Constants.failedToLoadTitle,
                              subtitle: Constants.failedToLoadSubtitle,
                              buttonText: Constants.failedToLoadButtonTitle)
    }

    enum Constants {
        static let failedToLoadTitle = NSLocalizedString(
            "pos.itemList.failedToLoadTitle",
            value: "Error loading products",
            comment: "Text appearing on the item list screen when there's an error loading products."
        )
        static let failedToLoadSubtitle = NSLocalizedString(
            "pos.itemList.failedToLoadSubtitle",
            value: "Give it another go?",
            comment: "Text appearing on the item list screen as subtitle when there's an error loading products."
        )
        static let failedToLoadButtonTitle = NSLocalizedString(
            "pos.itemList.failedToLoadButtonTitle",
            value: "Retry",
            comment: "Text for the button appearing on the item list screen when there's an error loading products."
        )
    }
}
