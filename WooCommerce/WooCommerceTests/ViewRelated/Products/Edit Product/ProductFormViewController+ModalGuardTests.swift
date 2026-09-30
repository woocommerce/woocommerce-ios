import Testing
import UIKit
import Yosemite

@testable import WooCommerce

/// Serialized because the tests share the app's key window state for real UIKit presentations.
@Suite(.serialized)
@MainActor
struct ProductFormViewController_ModalGuardTests {

    // MARK: dismissInProgressViewIfNeeded

    @Test func test_dismissInProgressViewIfNeeded_when_in_progress_view_is_presented_then_dismisses_it_and_calls_completion() async throws {
        // Given
        let context = TestContext()
        defer { context.cleanUp() }
        let (productForm, _, _) = makeProductForm(in: context)
        let navigationController = try #require(productForm.navigationController)
        let inProgressViewController = InProgressViewController(viewProperties: .init(title: "Saving", message: ""))
        navigationController.present(inProgressViewController, animated: false)
        var completionCallCount = 0

        // When
        productForm.dismissInProgressViewIfNeeded {
            completionCallCount += 1
        }

        // Then
        try await waitUntil { navigationController.presentedViewController == nil }
        try await waitUntil { completionCallCount == 1 }
    }

    @Test func test_dismissInProgressViewIfNeeded_when_another_modal_is_presented_then_leaves_it_and_calls_completion() throws {
        // Given
        let context = TestContext()
        defer { context.cleanUp() }
        let (productForm, _, _) = makeProductForm(in: context)
        let navigationController = try #require(productForm.navigationController)
        let otherModal = UIViewController()
        navigationController.present(otherModal, animated: false)
        var completionCallCount = 0

        // When
        productForm.dismissInProgressViewIfNeeded {
            completionCallCount += 1
        }

        // Then
        #expect(navigationController.presentedViewController === otherModal)
        #expect(completionCallCount == 1)
    }

    @Test func test_dismissInProgressViewIfNeeded_when_there_is_no_navigation_controller_then_calls_completion() {
        // Given
        let context = TestContext()
        defer { context.cleanUp() }
        let (productForm, _, _) = makeProductForm(in: context, embedInNavigationController: false)
        var completionCallCount = 0

        // When
        productForm.dismissInProgressViewIfNeeded {
            completionCallCount += 1
        }

        // Then
        #expect(productForm.navigationController == nil)
        #expect(completionCallCount == 1)
    }

    @Test func test_dismissInProgressViewIfNeeded_when_dismissal_is_in_flight_then_calls_completion_once_it_finishes() async throws {
        // Given
        let context = TestContext()
        defer { context.cleanUp() }
        let (productForm, _, _) = makeProductForm(in: context)
        let navigationController = try #require(productForm.navigationController)
        let inProgressViewController = InProgressViewController(viewProperties: .init(title: "Saving", message: ""))
        navigationController.present(inProgressViewController, animated: false)
        inProgressViewController.dismiss(animated: true, completion: nil)
        try await waitUntil { inProgressViewController.isBeingDismissed }
        var completionCallCount = 0

        // When
        productForm.dismissInProgressViewIfNeeded {
            completionCallCount += 1
        }

        // Then
        try await waitUntil { navigationController.presentedViewController == nil }
        try await waitUntil { completionCallCount == 1 }
    }

    // MARK: Bar button taps while a modal is attached

    @Test func test_saveProductAndLogEvent_when_a_modal_is_presented_then_ignores_the_tap() {
        // Given
        let context = TestContext()
        defer { context.cleanUp() }
        let (productForm, _, eventLogger) = makeProductForm(in: context)
        productForm.present(UIViewController(), animated: false)

        // When
        productForm.saveProductAndLogEvent()

        // Then
        #expect(eventLogger.updateButtonTappedCallCount == 0)
    }

    @Test func test_saveProductAndLogEvent_when_nothing_is_presented_then_handles_the_tap() {
        // Given
        let context = TestContext()
        defer { context.cleanUp() }
        let (productForm, _, eventLogger) = makeProductForm(in: context)

        // When
        productForm.saveProductAndLogEvent()

        // Then
        #expect(eventLogger.updateButtonTappedCallCount == 1)
    }

    @Test func test_publishProduct_when_a_modal_is_presented_then_ignores_the_tap() {
        // Given
        let context = TestContext()
        defer { context.cleanUp() }
        let draftProduct = Product.fake().copy(productID: 123, statusKey: ProductStatus.draft.rawValue)
        let (productForm, stores, _) = makeProductForm(in: context, product: draftProduct)
        productForm.present(UIViewController(), animated: false)

        // When
        productForm.publishProduct()

        // Then
        #expect(stores.receivedActions.containsProductUpdate == false)
    }

    @Test func test_publishProduct_when_nothing_is_presented_then_saves_the_product() {
        // Given
        let context = TestContext()
        defer { context.cleanUp() }
        let draftProduct = Product.fake().copy(productID: 123, statusKey: ProductStatus.draft.rawValue)
        let (productForm, stores, _) = makeProductForm(in: context, product: draftProduct)

        // When
        productForm.publishProduct()

        // Then
        #expect(stores.receivedActions.containsProductUpdate)
    }

    @Test func test_saveDraftAndDisplayProductPreview_when_a_modal_is_presented_then_ignores_the_tap() {
        // Given
        let context = TestContext()
        defer { context.cleanUp() }
        let newProduct = Product.fake().copy(productID: 0, statusKey: ProductStatus.published.rawValue)
        let (productForm, stores, _) = makeProductForm(in: context, product: newProduct, formType: .add)
        productForm.present(UIViewController(), animated: false)

        // When
        productForm.saveDraftAndDisplayProductPreview()

        // Then
        #expect(stores.receivedActions.containsProductAdd == false)
    }

    @Test func test_saveDraftAndDisplayProductPreview_when_nothing_is_presented_then_saves_the_draft() {
        // Given
        let context = TestContext()
        defer { context.cleanUp() }
        let newProduct = Product.fake().copy(productID: 0, statusKey: ProductStatus.published.rawValue)
        let (productForm, stores, _) = makeProductForm(in: context, product: newProduct, formType: .add)

        // When
        productForm.saveDraftAndDisplayProductPreview()

        // Then
        #expect(stores.receivedActions.containsProductAdd)
    }
}

// MARK: - Helpers

@MainActor
private extension ProductFormViewController_ModalGuardTests {
    func makeProductForm(in context: TestContext,
                         product: Product = Product.fake().copy(productID: 123),
                         formType: ProductFormType = .edit,
                         embedInNavigationController: Bool = true)
    -> (ProductFormViewController<ProductFormViewModel>, MockStoresManager, MockProductFormEventLogger) {
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let model = EditableProductModel(product: product)
        let imageActionHandler = ProductImageActionHandler(siteID: product.siteID,
                                                           productID: .product(id: product.productID),
                                                           imageStatuses: product.imageStatuses,
                                                           stores: stores)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: formType,
                                             productImageActionHandler: imageActionHandler,
                                             stores: stores)
        let eventLogger = MockProductFormEventLogger()
        let productForm = ProductFormViewController(viewModel: viewModel,
                                                    eventLogger: eventLogger,
                                                    productImageActionHandler: imageActionHandler,
                                                    presentationStyle: .navigationStack,
                                                    onDuplicateCompletion: { _, _ in })
        context.show(productForm, embedInNavigationController: embedInNavigationController)
        return (productForm, stores, eventLogger)
    }

    func waitUntil(timeout: TimeInterval = 2, _ condition: @escaping @MainActor () -> Bool) async throws {
        let deadline = Date(timeIntervalSinceNow: timeout)
        while !condition() {
            if Date() > deadline {
                Issue.record("Timed out waiting for condition")
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}

@MainActor
private final class TestContext {
    private let window = UIWindow(frame: UIScreen.main.bounds)

    func show(_ viewController: UIViewController, embedInNavigationController: Bool) {
        window.rootViewController = embedInNavigationController ? UINavigationController(rootViewController: viewController) : viewController
        window.makeKeyAndVisible()
        viewController.loadViewIfNeeded()
    }

    func cleanUp() {
        window.rootViewController?.presentedViewController?.dismiss(animated: false)
        window.isHidden = true
        window.rootViewController = nil
    }
}

private final class MockProductFormEventLogger: ProductFormEventLoggerProtocol {
    private(set) var updateButtonTappedCallCount = 0

    func logDescriptionTapped() {}
    func logImageTapped() {}
    func logPriceSettingsTapped() {}
    func logInventorySettingsTapped() {}
    func logShippingSettingsTapped() {}
    func logUpdateButtonTapped() {
        updateButtonTappedCallCount += 1
    }
    func logQuantityRulesTapped() {}
    func logSubscriptionsFreeTrialTapped() {}
    func logSubscriptionsExpirationDateTapped() {}
    func logQuantityRulesDoneButtonTapped(hasUnsavedChanges: Bool) {}
}

private extension Array where Element == Action {
    var containsProductUpdate: Bool {
        contains { action in
            guard let productAction = action as? ProductAction, case .updateProduct = productAction else {
                return false
            }
            return true
        }
    }

    var containsProductAdd: Bool {
        contains { action in
            guard let productAction = action as? ProductAction, case .addProduct = productAction else {
                return false
            }
            return true
        }
    }
}
