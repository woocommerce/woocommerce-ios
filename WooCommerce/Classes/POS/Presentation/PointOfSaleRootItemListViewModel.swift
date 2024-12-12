import SwiftUI
import Yosemite
import WooFoundation

// TODO: Maybe not a view helper because it's not stateless
// TODO: Try replacing this with another `PointOfSaleItemsController` for child items
final class PointOfSaleRootItemListViewModel: ObservableObject {
    @Published var itemListState: ItemListState = .initialLoading
    @Published var variationItemListState: ItemListState = .empty
    @Published var isShowingLoadingView: Bool = false

    private let itemsController: PointOfSaleItemsControllerProtocol
    private(set) var variationChildItemsController: PointOfSaleItemsControllerProtocol?

//    @Published var childItemListState: ItemListState = .empty
//    private var allChildItems: [UUID: [POSItem]] = [:]
//    private let variationProvider: PointOfSaleVariationServiceProtocol
//    private var currentPage: Int = Constants.initialPage
//    private var mightHaveMorePages: Bool = true

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
                    .scan(false) { hasShownLoadingView, newState in
                        // If never set to true, check condition
                        if !hasShownLoadingView && newState == .initialLoading {
                            return true
                        }
                        // Allow resetting to false
                        return hasShownLoadingView && newState != .initialLoading ? false : hasShownLoadingView
                    }
                    .assign(to: &$isShowingLoadingView)
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
