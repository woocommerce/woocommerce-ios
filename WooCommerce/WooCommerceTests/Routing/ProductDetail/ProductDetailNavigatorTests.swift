@testable import WooCommerce
import Testing
import Yosemite

@MainActor
final class ProductDetailNavigatorTests {
    private static let aNonBookingProduct = Product.fake().copy(productTypeKey: "simple")
    private static let aBookingProduct = Product.fake().copy(productTypeKey: "booking")
    private lazy var coordinatorFactory = MockProductDetailCoordinatorFactory()

    @Test(arguments: [
        (isCIABSite: true, product: aNonBookingProduct),
        (isCIABSite: false, product: aBookingProduct),
        (isCIABSite: false, product: aNonBookingProduct),
    ])
    private func regardlessOfCIABSiteWeShouldDirectToNative(isCIABSite: Bool, product: Product) {
        let navigator = ProductDetailNavigator(
            ciabChecker: MockCIABEligibilityChecker(mockedIsCurrentSiteCIAB: isCIABSite),
            coordinatorFactory: coordinatorFactory
        )
        _ = navigator.makeDestination(product: product, isReadOnly: false)
        #expect(coordinatorFactory.createdNativeCoordiantor)
        #expect(!coordinatorFactory.createdWebCoordiantor)
    }

    @Test
    private func bookableProductOnCIABSiteWeShouldDirectToWeb() {
        let navigator = ProductDetailNavigator(
            ciabChecker: MockCIABEligibilityChecker(mockedIsCurrentSiteCIAB: true),
            coordinatorFactory: coordinatorFactory
        )
        _ = navigator.makeDestination(product: Self.aBookingProduct, isReadOnly: false)
        #expect(coordinatorFactory.createdWebCoordiantor)
        #expect(!coordinatorFactory.createdNativeCoordiantor)
    }
}
