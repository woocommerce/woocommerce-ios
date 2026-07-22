import Testing
import UIKit
import Yosemite
import protocol WooFoundation.Analytics

@testable import WooCommerce

@MainActor
@Suite(.serialized)
struct ProductFormViewController_DuplicationTests {
    @Test func test_duplicate_when_saved_product_is_unchanged_then_starts_immediately() {
        // Given
        let context = TestContext()
        defer { context.cleanUp() }
        let product = Product.fake().copy(productID: 123, name: "Saved product")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let (productForm, _, _) = createProductForm(product: product, stores: stores)
        var duplicationStarted = false
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            if case .duplicateProduct = action {
                duplicationStarted = true
            }
        }

        // When
        productForm.handleProductDuplication()

        // Then
        #expect(duplicationStarted)
        #expect(productForm.presentedViewController == nil)
    }

    @Test func test_duplicate_when_product_is_edited_then_shows_confirmation_and_cancel_retains_draft() async throws {
        // Given
        let context = TestContext()
        defer { context.cleanUp() }
        let savedImage = ProductImage.fake().copy(imageID: 1)
        let draftImage = ProductImage.fake().copy(imageID: 2)
        let product = Product.fake().copy(productID: 123, name: "Saved product", images: [savedImage])
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let (productForm, viewModel, imageActionHandler) = createProductForm(product: product,
                                                                            stores: stores,
                                                                            password: "saved-password")
        viewModel.updateName("Unsaved product")
        viewModel.updateImages([draftImage])
        viewModel.updateProductSettings(ProductSettings(from: viewModel.productModel.product, password: "unsaved-password"))
        imageActionHandler.updateProductImageStatusesAfterReordering(product.copy(images: [draftImage]).imageStatuses)
        try await waitUntil { imageActionHandler.productImageStatuses.images == [draftImage] }
        context.present(productForm)

        // When
        productForm.handleProductDuplication()

        // Then
        let alert = try #require(productForm.presentedViewController as? UIAlertController)
        #expect(alert.title == "Discard changes and duplicate?")
        #expect(alert.message == "Your unsaved changes will be lost. The duplicate will use the last saved version.")
        #expect(alert.actions.map(\.title) == ["Cancel", "Discard & duplicate"])
        #expect(alert.actions.map(\.style) == [.cancel, .destructive])
        #expect(stores.receivedActions.containsProductDuplication == false)
        #expect(context.duplicateResultAnalyticsEvents.isEmpty)

        // When cancelling
        alert.tapButton(atIndex: 0)

        // Then the exact live draft is retained and no result action is sent.
        #expect(viewModel.productModel.name == "Unsaved product")
        #expect(viewModel.productModel.images == [draftImage])
        #expect(viewModel.password == "unsaved-password")
        #expect(imageActionHandler.productImageStatuses.images == [draftImage])
        #expect(viewModel.hasUnsavedChanges())
        #expect(stores.receivedActions.containsProductDuplication == false)
        #expect(context.duplicateResultAnalyticsEvents.isEmpty)
    }

    @Test func test_duplicate_when_confirmed_and_successful_then_uses_intent_snapshot_and_discards_draft() async throws {
        // Given
        let context = TestContext()
        defer { context.cleanUp() }
        let savedImage = ProductImage.fake().copy(imageID: 1)
        let draftImage = ProductImage.fake().copy(imageID: 2)
        let product = Product.fake().copy(productID: 123, name: "Saved product", images: [savedImage], variations: [11])
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let (productForm, viewModel, imageActionHandler) = createProductForm(product: product,
                                                                            stores: stores,
                                                                            password: "saved-password")
        viewModel.updateName("Unsaved product")
        viewModel.updateImages([draftImage])
        viewModel.updateProductSettings(ProductSettings(from: viewModel.productModel.product, password: "unsaved-password"))
        imageActionHandler.updateProductImageStatusesAfterReordering(product.copy(images: [draftImage]).imageStatuses)
        try await waitUntil { imageActionHandler.productImageStatuses.images == [draftImage] }
        var duplicatedSourceID: Int64?
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .duplicateProduct(_, productID, onCompletion):
                duplicatedSourceID = productID
                onCompletion(.success(456))
            case let .retrieveProduct(_, _, onCompletion):
                onCompletion(.success(product.copy(productID: 456, name: "Saved product Copy")))
            default:
                break
            }
        }
        context.present(productForm)

        // When the initial intent captures product ID 123
        productForm.handleProductDuplication()
        let alert = try #require(productForm.presentedViewController as? UIAlertController)

        // And the persisted baseline changes while the alert is visible
        viewModel.updateProductVariations(from: product.copy(productID: 999, variations: [99]))
        #expect(viewModel.productModel.name == "Unsaved product")
        #expect(viewModel.productModel.productID == 999)

        // And duplication is confirmed
        alert.tapButton(atIndex: 1)

        // Then the captured source is duplicated and the live draft is discarded only after success.
        #expect(duplicatedSourceID == 123)
        #expect(viewModel.productModel == EditableProductModel(product: product))
        #expect(viewModel.originalProductModel == EditableProductModel(product: product))
        #expect(viewModel.password == "saved-password")
        try await waitUntil { imageActionHandler.productImageStatuses.images == [savedImage] }
        #expect(viewModel.hasUnsavedChanges() == false)
        #expect(context.duplicateResultAnalyticsEvents == [WooAnalyticsStat.duplicateProductSuccess.rawValue])
    }

    @Test func test_duplicate_when_confirmed_and_failed_then_retains_live_draft() async throws {
        // Given
        let context = TestContext()
        defer { context.cleanUp() }
        let savedImage = ProductImage.fake().copy(imageID: 1)
        let draftImage = ProductImage.fake().copy(imageID: 2)
        let product = Product.fake().copy(productID: 123, name: "Saved product", images: [savedImage])
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let (productForm, viewModel, imageActionHandler) = createProductForm(product: product,
                                                                            stores: stores,
                                                                            password: "saved-password")
        viewModel.updateName("Unsaved product")
        viewModel.updateImages([draftImage])
        viewModel.updateProductSettings(ProductSettings(from: viewModel.productModel.product, password: "unsaved-password"))
        imageActionHandler.updateProductImageStatusesAfterReordering(product.copy(images: [draftImage]).imageStatuses)
        try await waitUntil { imageActionHandler.productImageStatuses.images == [draftImage] }
        let error = NSError(domain: "ProductDuplicate", code: 500)
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let .duplicateProduct(_, _, onCompletion) = action {
                onCompletion(.failure(.unknown(error: AnyError(error))))
            }
        }
        context.present(productForm)

        // When
        productForm.handleProductDuplication()
        let alert = try #require(productForm.presentedViewController as? UIAlertController)
        alert.tapButton(atIndex: 1)

        // Then
        #expect(viewModel.productModel.name == "Unsaved product")
        #expect(viewModel.productModel.images == [draftImage])
        #expect(viewModel.password == "unsaved-password")
        #expect(imageActionHandler.productImageStatuses.images == [draftImage])
        #expect(viewModel.hasUnsavedChanges())
        #expect(context.duplicateResultAnalyticsEvents == [WooAnalyticsStat.duplicateProductFailed.rawValue])
    }

    @Test func test_duplicate_when_edit_product_has_productID_zero_then_no_ops_before_progress_or_request() {
        // Given
        let context = TestContext()
        defer { context.cleanUp() }
        let product = Product.fake().copy(productID: 0)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let (productForm, _, _) = createProductForm(product: product, stores: stores)

        // When
        productForm.handleProductDuplication()

        // Then
        #expect(productForm.presentedViewController == nil)
        #expect(stores.receivedActions.containsProductDuplication == false)
        #expect(context.duplicateResultAnalyticsEvents.isEmpty)
    }
}

@MainActor
private extension ProductFormViewController_DuplicationTests {
    func createProductForm(product: Product,
                           stores: StoresManager,
                           password: String? = nil) -> (ProductFormViewController<ProductFormViewModel>,
                                                         ProductFormViewModel,
                                                         ProductImageActionHandler) {
        let model = EditableProductModel(product: product)
        let imageActionHandler = ProductImageActionHandler(siteID: product.siteID,
                                                           productID: .product(id: product.productID),
                                                           imageStatuses: product.imageStatuses,
                                                           stores: stores)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .edit,
                                             productImageActionHandler: imageActionHandler,
                                             stores: stores)
        viewModel.resetPassword(password)
        let productForm = ProductFormViewController(viewModel: viewModel,
                                                    eventLogger: ProductFormEventLogger(),
                                                    productImageActionHandler: imageActionHandler,
                                                    presentationStyle: .navigationStack)
        return (productForm, viewModel, imageActionHandler)
    }

    func waitUntil(_ condition: @escaping @MainActor () -> Bool) async throws {
        for _ in 0..<100 {
            if condition() {
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        #expect(condition())
    }
}

@MainActor
private final class TestContext {
    private let originalAnalytics: Analytics
    let analyticsProvider = MockAnalyticsProvider()
    let window = UIWindow(frame: UIScreen.main.bounds)

    init() {
        originalAnalytics = ServiceLocator.analytics
        ServiceLocator.setAnalytics(WooAnalytics(analyticsProvider: analyticsProvider))
        window.makeKeyAndVisible()
    }

    var duplicateResultAnalyticsEvents: [String] {
        analyticsProvider.receivedEvents.filter {
            $0 == WooAnalyticsStat.duplicateProductSuccess.rawValue ||
                $0 == WooAnalyticsStat.duplicateProductFailed.rawValue
        }
    }

    func present(_ viewController: UIViewController) {
        window.rootViewController = viewController
        viewController.loadViewIfNeeded()
    }

    func cleanUp() {
        window.resignKey()
        window.rootViewController = nil
        ServiceLocator.setAnalytics(originalAnalytics)
    }
}

private extension Array where Element == Action {
    var containsProductDuplication: Bool {
        contains { action in
            guard let productAction = action as? ProductAction else {
                return false
            }
            if case .duplicateProduct = productAction {
                return true
            }
            return false
        }
    }
}
