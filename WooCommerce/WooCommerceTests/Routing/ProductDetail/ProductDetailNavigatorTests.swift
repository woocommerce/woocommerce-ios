@testable import WooCommerce
import Testing
import Yosemite

@MainActor
final class ProductDetailNavigatorTests {
    private static let aNonBookingProduct = Product.fake().copy(productTypeKey: "simple")
    private static let aBookingProduct = Product.fake().copy(productTypeKey: "bookable-service")
    private lazy var coordinatorFactory = MockProductDetailCoordinatorFactory()

    @Test(arguments: [
        (isCIABSite: true, product: aNonBookingProduct),
        (isCIABSite: false, product: aNonBookingProduct),
    ])
    func non_bookable_product_directs_to_native_view_regardless_of_CIAB(isCIABSite: Bool, product: Product) {
        // Given
        let navigator = ProductDetailNavigator(
            ciabChecker: MockCIABEligibilityChecker(mockedIsCurrentSiteCIAB: isCIABSite),
            coordinatorFactory: coordinatorFactory
        )

        // When
        _ = navigator.makeDestination(product: product, isReadOnly: false)

        // Then
        #expect(coordinatorFactory.createdNativeCoordiantor)
        #expect(!coordinatorFactory.createdWebCoordiantor)
    }

    @Test
    func bookable_product_on_CIAB_site_directs_to_web_view() {
        // Given
        let navigator = ProductDetailNavigator(
            ciabChecker: MockCIABEligibilityChecker(mockedIsCurrentSiteCIAB: true),
            coordinatorFactory: coordinatorFactory
        )

        // When
        _ = navigator.makeDestination(product: Self.aBookingProduct, isReadOnly: false)

        // Then
        #expect(coordinatorFactory.createdWebCoordiantor)
        #expect(!coordinatorFactory.createdNativeCoordiantor)
    }

    @Test
    func bookable_product_on_non_CIAB_site_directs_to_native_view() {
        // Given
        let navigator = ProductDetailNavigator(
            ciabChecker: MockCIABEligibilityChecker(mockedIsCurrentSiteCIAB: false),
            coordinatorFactory: coordinatorFactory
        )

        // When
        _ = navigator.makeDestination(product: Self.aBookingProduct, isReadOnly: false)

        // Then
        #expect(coordinatorFactory.createdNativeCoordiantor)
        #expect(!coordinatorFactory.createdWebCoordiantor)
    }
}
