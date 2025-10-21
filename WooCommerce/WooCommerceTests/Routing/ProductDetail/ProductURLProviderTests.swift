@testable import WooCommerce
import Testing
import Yosemite

final class ProductURLProviderTests {

    private let storeURL = "https://nicestore.com"
    private let productID: Int64 = 1234567
    private lazy var aProduct = Product.fake().copy(productID: productID)
    private lazy var aSite = Site.fake().copy(url: storeURL)

    @Test
    private func validateEditAdminURL() async throws {
        let url = try #require(ProductURLProvider.editAdminURL(for: aProduct, site: aSite))
        #expect(url.absoluteString ==
                "\(storeURL)/wp-admin?page=next-admin&p=/woocommerce/products/edit/\(productID)")
    }
}

@MainActor
final class ProductDetailPresenterTests {
    private static let aNonBookingProduct = Product.fake().copy(productTypeKey: "simple")
    private static let aBookingProduct = Product.fake().copy(productTypeKey: "booking")
    private lazy var coordinatorFactory = MockProductDetailCoordinatorFactory()

    @Test(arguments: [
        (isCIABSite: true, product: aNonBookingProduct),
        (isCIABSite: false, product: aBookingProduct),
        (isCIABSite: false, product: aNonBookingProduct),
    ])
    private func regardlessOfCIABSiteWeShouldDirectToNative(isCIABSite: Bool, product: Product) {
        let router = ProductDetailPresenter(
            ciabChecker: MockCIABEligibilityChecker(mockedIsCurrentSiteCIAB: isCIABSite),
            coordinatorFactory: coordinatorFactory
        )
        _ = router.viewController(product: product, forceReadOnly: false)
        #expect(coordinatorFactory.createdNativeCoordiantor)
        #expect(!coordinatorFactory.createdWebCoordiantor)
    }

    @Test
    private func bookableProductOnCIABSiteWeShouldDirectToWeb() {
        let router = ProductDetailPresenter(
            ciabChecker: MockCIABEligibilityChecker(mockedIsCurrentSiteCIAB: true),
            coordinatorFactory: coordinatorFactory
        )
        _ = router.viewController(product: Self.aBookingProduct, forceReadOnly: false)
        #expect(coordinatorFactory.createdWebCoordiantor)
        #expect(!coordinatorFactory.createdNativeCoordiantor)
    }
}

class MockProductDetailCoordinatorFactory: ProductDetailCoordinatorFactoryProtocol {
    private(set) var createdWebCoordiantor = false
    private(set) var createdNativeCoordiantor = false

    func webCoordinator() -> ProductDetailCoordinator {
        createdWebCoordiantor = true
        return MockProductDetailCoordinator()
    }

    func nativeCoordinator() -> ProductDetailCoordinator {
        createdNativeCoordiantor = true
        return MockProductDetailCoordinator()
    }
}

import UIKit

struct MockProductDetailCoordinator: ProductDetailCoordinator {
    func viewController(product: Product,
                        presentationStyle: ProductDetailPresenter.PresentationStyle,
                        forceReadOnly: Bool,
                        onDeleteCompletion: (() -> Void)?) -> UIViewController {
        UIViewController()
    }
}
