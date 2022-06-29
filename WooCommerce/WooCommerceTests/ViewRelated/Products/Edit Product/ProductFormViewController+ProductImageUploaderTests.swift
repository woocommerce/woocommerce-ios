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
        let actionHandler = ProductImageActionHandler(siteID: 134, productID: 256, imageStatuses: [])
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
        let actionHandler = ProductImageActionHandler(siteID: 134, productID: 256, imageStatuses: [])
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
        let actionHandler = ProductImageActionHandler(siteID: 134, productID: 256, imageStatuses: [])
        let productImageUploader = MockProductImageUploader()
        let productForm = ProductFormViewController(viewModel:
                                                        ProductFormViewModel(product: .init(product: .fake()),
                                                                             formType: .edit,
                                                                             productImageActionHandler: actionHandler),
                                                    eventLogger: ProductFormEventLogger(),
                                                    productImageActionHandler: actionHandler,
                                                    presentationStyle: .navigationStack,
                                                    productImageUploader: productImageUploader)
        let rootNavigationController = UINavigationController(rootViewController: .init())
        window.rootViewController = rootNavigationController

        // When
        rootNavigationController.pushViewController(productForm, animated: false)

        waitUntil {
            rootNavigationController.viewControllers.count == 2
        }

        rootNavigationController.popViewController(animated: false)

        waitUntil {
            rootNavigationController.viewControllers.count == 1
        }

        // Then
        XCTAssertTrue(productImageUploader.startEmittingErrorsWasCalled)
    }
}
