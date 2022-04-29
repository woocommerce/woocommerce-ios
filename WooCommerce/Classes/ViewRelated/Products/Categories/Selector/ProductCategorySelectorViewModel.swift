import Foundation
import protocol Storage.StorageManagerType
import Yosemite

/// View model for `ProductCategorySelector`.
///
final class ProductCategorySelectorViewModel: ObservableObject {
    private let siteID: Int64
    private let onCategorySelection: ([ProductCategory]) -> Void
    private var selectedCategories: [Int64]
    private let stores: StoresManager
    private let storageManager: StorageManagerType

    let listViewModel: ProductCategoryListViewModel

    @Published private(set) var selectedItemsCount: Int = 0

    init(siteID: Int64,
         selectedCategories: [Int64] = [],
         storesManager: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         onCategorySelection: @escaping ([ProductCategory]) -> Void) {
        self.siteID = siteID
        self.selectedCategories = selectedCategories
        self.onCategorySelection = onCategorySelection
        self.stores = storesManager
        self.storageManager = storageManager

        listViewModel = .init(siteID: siteID,
                              selectedCategoryIDs: selectedCategories,
                              storesManager: stores,
                              storageManager: storageManager)
        listViewModel.$selectedCategories
            .map { $0.count }
            .assign(to: &$selectedItemsCount)
    }

    /// Triggered when selection is done.
    ///
    func submitSelection() {
        onCategorySelection(listViewModel.selectedCategories)
    }
}
