import SwiftUI
import Yosemite
import WooFoundation

enum PointOfSaleItemListFullscreenState: Identifiable {
    case initialLoading
    case empty
    case error(PointOfSaleErrorState)

    var id: String {
        switch self {
            case .initialLoading:
                return "initialLoading"
            case .empty:
                return "empty"
            case .error(let errorState):
                // Assuming PointOfSaleErrorState handles its own unique identification
                return "error-\(errorState)"
        }
    }
}

final class PointOfSaleRootItemListViewModel: ObservableObject {
    @Published var itemListState: ItemListState = .initialLoading
    @Published var variationItemListState: ItemListState = .empty
    @Published var fullscreenState: PointOfSaleItemListFullscreenState?

    private let itemsController: PointOfSaleItemsControllerProtocol
    private(set) var variationChildItemsController: PointOfSaleItemsControllerProtocol?

    private let siteID: Int64
    private let credentials: Credentials
    private let currencySettings: CurrencySettings

    private var variationServicesByParentID: [Int64: PointOfSaleVariationService] = [:]

    init() {
        self.siteID = ServiceLocator.stores.sessionManager.defaultStoreID!
        self.credentials = ServiceLocator.stores.sessionManager.defaultCredentials!
        self.currencySettings = ServiceLocator.currencySettings

        let productProvider = PointOfSaleProductService(siteID: ServiceLocator.stores.sessionManager.defaultStoreID!,
                                                        currencySettings: ServiceLocator.currencySettings,
                                                        credentials: ServiceLocator.stores.sessionManager.defaultCredentials!,
                                                        isVariableProductsFeatureEnabled: true)
        self.itemsController = PointOfSaleItemsController(itemProvider: productProvider)
        publishItemListState()

        $itemListState
            .map { itemListState in
                switch itemListState {
                    case .initialLoading:
                        return .initialLoading
                    case .empty:
                        return .empty
                    case .error(let error):
                        return .error(error)
                    case .loaded, .loading:
                        return nil
                }
            }
            .assign(to: &$fullscreenState)
    }

    func showVariationItems(for parentProduct: POSVariableProductParent) {
        let service: PointOfSaleVariationService = {
            if let service = variationServicesByParentID[parentProduct.productID] {
                return service
            } else {
                let service = PointOfSaleVariationService(siteID: siteID,
                                                          currencySettings: currencySettings,
                                                          credentials: credentials,
                                                          parentProduct: parentProduct)
                variationServicesByParentID[parentProduct.productID] = service
                return service
            }
        }()
        let itemsController = PointOfSaleItemsController(itemProvider: service)
        variationChildItemsController = itemsController
        publishVariationItemListState()
        Task {
            await itemsController.loadInitialItems()
        }
    }
}

extension PointOfSaleRootItemListViewModel {
    private func publishItemListState() {
        itemsController.itemListStatePublisher.assign(to: &$itemListState)
    }

    @MainActor
    func loadInitialItems() async {
        await itemsController.loadInitialItems()
    }

    @MainActor
    func loadNextItems() async {
        await itemsController.loadNextItems()
    }

    @MainActor
    func reload() async {
        await itemsController.reload()
    }
}

extension PointOfSaleRootItemListViewModel {
    private func publishVariationItemListState() {
        variationChildItemsController?.itemListStatePublisher.assign(to: &$variationItemListState)
    }

    @MainActor
    func loadVariationInitialItems() async {
        await variationChildItemsController?.loadInitialItems()
    }

    @MainActor
    func loadVariationNextItems() async {
        await variationChildItemsController?.loadNextItems()
    }

    @MainActor
    func reloadVariations() async {
        await variationChildItemsController?.reload()
    }
}

private enum Constants {
    static let initialPage: Int = 1
}
