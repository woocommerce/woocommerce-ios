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

    private(set) lazy var listViewModel: ProductCategoryListViewModel = {
        .init(storesManager: stores,
              siteID: siteID,
              selectedCategoryIDs: selectedCategories) { [weak self] _ in
            guard let self = self else { return }
            self.selectedItemsCount = self.listViewModel.selectedCategories.count
        }
    }()

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
    }

    /// Triggered when selection is done.
    ///
    func submitSelection() {
        onCategorySelection(listViewModel.selectedCategories)
    }
}
