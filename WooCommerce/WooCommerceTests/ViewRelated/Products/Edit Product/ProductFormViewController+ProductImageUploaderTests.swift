import Combine
import XCTest

@testable import WooCommerce

final class ProductFormViewController_ProductImageUploaderTests: XCTestCase {
    private let window = UIWindow(frame: UIScreen.main.bounds)

    override func setUp() {
        super.setUp()
        window.makeKeyAndVisible()
    }

    override func tearDown() {
        window.resignKey()
        window.rootViewController = nil

        super.tearDown()
    }

    func test_triggering_viewDidLoad_invokes_stopEmittingErrors() throws {
        // Given
        let actionHandler = ProductImageActionHandler(siteID: 134, productID: .product(id: 256), imageStatuses: [])
        let productImageUploader = MockProductImageUploader()

        // When
        let productForm = ProductFormViewController(viewModel:
                                                        ProductFormViewModel(product: .init(product: .fake()),
                                                                             formType: .edit,
                                                                             productImageActionHandler: actionHandler),
                                                    eventLogger: ProductFormEventLogger(),
                                                    productImageActionHandler: actionHandler,
                                                    presentationStyle: .navigationStack,
                                                    productImageUploader: productImageUploader)
        productForm.viewDidLoad()

        // Then
        XCTAssertFalse(productImageUploader.startEmittingErrorsWasCalled)
        XCTAssertTrue(productImageUploader.stopEmittingErrorsWasCalled)
    }

    func test_dismissing_product_form_invokes_startEmittingErrors() throws {
        // Given
        let actionHandler = ProductImageActionHandler(siteID: 134, productID: .product(id: 256), imageStatuses: [])
        let productImageUploader = MockProductImageUploader()
        let productForm = ProductFormViewController(viewModel:
                                                        ProductFormViewModel(product: .init(product: .fake()),
                                                                             formType: .edit,
                                                                             productImageActionHandler: actionHandler),
                                                    eventLogger: ProductFormEventLogger(),
                                                    productImageActionHandler: actionHandler,
                                                    presentationStyle: .navigationStack,
                                                    productImageUploader: productImageUploader)
        let rootViewController = UIViewController()
        window.rootViewController = rootViewController

        // When
        let _: Void = waitFor { promise in
            rootViewController.present(productForm, animated: false) {
                rootViewController.dismiss(animated: false) {
                    promise(())
                }
            }
        }

        // Then
        XCTAssertTrue(productImageUploader.startEmittingErrorsWasCalled)
    }

    func test_popping_product_form_invokes_startEmittingErrors() throws {
        // Given
        let actionHandler = ProductImageActionHandler(siteID: 134, productID: .product(id: 256), imageStatuses: [])
        let productImageUploader = MockProductImageUploader()
        let productForm = ProductFormViewController(viewModel:
                                                        ProductFormViewModel(product: .init(product: .fake()),
                                                                             formType: .edit,
                                                                             productImageActionHandler: actionHandler),
                                                    eventLogger: ProductFormEventLogger(),
                                                    productImageActionHandler: actionHandler,
                                                    presentationStyle: .navigationStack,
                                                    productImageUploader: productImageUploader)
        let rootNavigationController = MockNavigationController(rootViewController: .init())
        window.rootViewController = rootNavigationController

        // When
        rootNavigationController.pushViewController(productForm, animated: false)
        // And
        rootNavigationController.popViewController(animated: false)

        // Then
        XCTAssertTrue(productImageUploader.startEmittingErrorsWasCalled)
    }
}

// MARK: - MockNavigationController
/// Popping with UINavigationController doesn't work reliably in unit tests and doesn't always result in viewWillDisappear being called.
/// Created a mock to simulate the behavior of UINavigationController.
///
private class MockNavigationController: UINavigationController {
    private var pushedViewControllers: [UIViewController] = []
    private var isBeingDismissedToReturn: Bool = false

    override var isBeingDismissed: Bool {
        isBeingDismissedToReturn
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: true)
        isBeingDismissedToReturn = false
        pushedViewControllers.append(viewController)
    }

    @discardableResult
    override func popViewController(animated: Bool) -> UIViewController? {
        let viewController = pushedViewControllers.popLast()
        isBeingDismissedToReturn = true
        viewController?.viewWillDisappear(animated)
        return super.popViewController(animated: animated)
    }
}
