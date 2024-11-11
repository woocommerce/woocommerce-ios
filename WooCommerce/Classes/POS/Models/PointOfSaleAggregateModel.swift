import Foundation

import protocol Yosemite.POSItem
import protocol Yosemite.POSItemProvider

protocol PointOfSaleAggregateModelProtocol {
    @available(*, deprecated, message: "`allItems` is due for removal, use `itemListState` instead.")
    var allItems: [POSItem] { get }
    var itemListState: ItemListState { get }

    func loadInitialItems() async
    func loadItems(pageNumber: Int) async
    func reload() async
}

class PointOfSaleAggregateModel: ObservableObject, PointOfSaleAggregateModelProtocol {
    @Published private(set) var allItems: [POSItem] = []
    @Published private(set) var itemListState: ItemListState = .initialLoading

    private let itemProvider: POSItemProvider

    init(itemProvider: POSItemProvider) {
        self.itemProvider = itemProvider
    }
}

// MARK: - ItemList
extension PointOfSaleAggregateModel {
    @MainActor
    func loadInitialItems() async {
        itemListState = .initialLoading
        await load(pageNumber: Constants.initialPage)
    }

    @MainActor
    func loadItems(pageNumber: Int) async {
        itemListState = .loading(allItems)
        await load(pageNumber: pageNumber)
    }

    @MainActor
    func reload() async {
        allItems.removeAll()
        await loadItems(pageNumber: Constants.initialPage)
    }

    @MainActor
    private func load(pageNumber: Int) async {
        do {
            try await fetchItems(pageNumber: pageNumber)
        } catch {
            itemListState = .error(PointOfSaleErrorState.errorOnLoadingProducts())
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
