@testable import WooCommerce
import Testing
import Yosemite

@MainActor
final class ProductDetailNavigatorTests {
    private static let aNonBookingProduct = Product.fake().copy(productTypeKey: "simple")
    private static let aNewBookingProduct = Product.fake().copy(productTypeKey: "bookable-service")
    private static let aLegacyBookingProduct = Product.fake().copy(productTypeKey: "booking")
    private lazy var coordinatorFactory = MockProductDetailCoordinatorFactory()

    // MARK: - Non-bookable products

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

    // MARK: - New booking type (bookable-service)

    @Test
    func new_booking_product_on_CIAB_site_directs_to_web_view() {
        // Given
        let navigator = ProductDetailNavigator(
            ciabChecker: MockCIABEligibilityChecker(mockedIsCurrentSiteCIAB: true),
            coordinatorFactory: coordinatorFactory
        )

        // When
        _ = navigator.makeDestination(product: Self.aNewBookingProduct, isReadOnly: false)

        // Then
        #expect(coordinatorFactory.createdWebCoordiantor)
        #expect(!coordinatorFactory.createdNativeCoordiantor)
    }

    @Test
    func new_booking_product_on_non_CIAB_site_directs_to_native_view() {
        // Given
        let navigator = ProductDetailNavigator(
            ciabChecker: MockCIABEligibilityChecker(mockedIsCurrentSiteCIAB: false),
            coordinatorFactory: coordinatorFactory
        )

        // When
        _ = navigator.makeDestination(product: Self.aNewBookingProduct, isReadOnly: false)

        // Then
        #expect(coordinatorFactory.createdNativeCoordiantor)
        #expect(!coordinatorFactory.createdWebCoordiantor)
    }

    // MARK: - Legacy booking type

    @Test(arguments: [true, false])
    func legacy_booking_product_directs_to_web_view_regardless_of_CIAB(isCIABSite: Bool) {
        // Given
        let navigator = ProductDetailNavigator(
            ciabChecker: MockCIABEligibilityChecker(mockedIsCurrentSiteCIAB: isCIABSite),
            coordinatorFactory: coordinatorFactory
        )

        // When
        _ = navigator.makeDestination(product: Self.aLegacyBookingProduct, isReadOnly: false)

        // Then
        #expect(coordinatorFactory.createdWebCoordiantor)
        #expect(!coordinatorFactory.createdNativeCoordiantor)
    }
}
