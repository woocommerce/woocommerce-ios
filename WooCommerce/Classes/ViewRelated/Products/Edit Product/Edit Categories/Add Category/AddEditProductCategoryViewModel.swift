import Foundation
import Yosemite

/// View model for `AddEditProductCategoryViewController`.
final class AddEditProductCategoryViewModel {

    typealias Completion = (_ category: ProductCategory) -> Void

    enum EditingMode {
        case add
        case editing
    }

    let siteID: Int64
    private let onCompletion: Completion
    private let stores: StoresManager
    private(set) var editingMode: EditingMode
    private(set) var currentCategory: ProductCategory?

    @Published var categoryTitle: String {
        didSet {
            updateSaveButton()
        }
    }

    @Published var selectedParentCategory: ProductCategory? {
        didSet {
            updateSaveButton()
        }
    }

    @Published private(set) var saveEnabled = false

    init(siteID: Int64,
         existingCategory: ProductCategory? = nil,
         parentCategory: ProductCategory? = nil,
         stores: StoresManager = ServiceLocator.stores,
         onCompletion: @escaping Completion) {
        self.siteID = siteID
        self.currentCategory = existingCategory
        self.stores = stores
        self.editingMode = existingCategory != nil ? .editing : .add
        self.onCompletion = onCompletion
        self.categoryTitle = existingCategory?.name ?? ""
        self.selectedParentCategory = parentCategory
    }

    @MainActor
    func saveCategory() async throws {
        switch editingMode {
        case .add:
            let newCategory = try await addNewCategory()
            onCompletion(newCategory)
        case .editing:
            guard let currentCategory else {
                return
            }
            let updatedCategory = try await updateCategory(
                .init(categoryID: currentCategory.categoryID,
                      siteID: siteID,
                      parentID: selectedParentCategory?.categoryID ?? 0,
                      name: categoryTitle,
                      slug: "")
            )
            onCompletion(updatedCategory)
        }
    }
}

private extension AddEditProductCategoryViewModel {
    func updateSaveButton() {
        saveEnabled = {
            switch editingMode {
            case .add:
                return categoryTitle.isNotEmpty
            case .editing:
                return categoryTitle.isNotEmpty && (
                    categoryTitle != currentCategory?.name ||
                    selectedParentCategory?.categoryID ?? 0 != currentCategory?.parentID
                )
            }
        }()
    }

    @MainActor
    func addNewCategory() async throws -> ProductCategory {
        return try await withCheckedThrowingContinuation { continuation in
            let action = ProductCategoryAction.addProductCategory(siteID: siteID,
                                                                  name: categoryTitle,
                                                                  parentID: selectedParentCategory?.categoryID) { result in
                switch result {
                case .success(let category):
                    continuation.resume(returning: category)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            stores.dispatch(action)
        }
    }

    @MainActor
    func updateCategory(_ category: ProductCategory) async throws -> ProductCategory {
        return try await withCheckedThrowingContinuation { continuation in
            let action = ProductCategoryAction.updateProductCategory(category) { result in
                switch result {
                case .success(let updatedCategory):
                    continuation.resume(returning: updatedCategory)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            stores.dispatch(action)
        }
    }
}
