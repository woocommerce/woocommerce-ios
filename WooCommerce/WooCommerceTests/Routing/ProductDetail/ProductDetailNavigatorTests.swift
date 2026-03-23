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

    @Test
    func non_bookable_product_directs_to_native_view_with_standard_routing() {
        // Given
        let navigator = ProductDetailNavigator(
            productRouting: StandardProductRoutingProvider(),
            coordinatorFactory: coordinatorFactory
        )

        // When
        _ = navigator.makeDestination(product: Self.aNonBookingProduct, isReadOnly: false)

        // Then
        #expect(coordinatorFactory.createdNativeCoordiantor)
        #expect(!coordinatorFactory.createdWebCoordiantor)
    }

    @Test
    func non_bookable_product_directs_to_native_view_with_ciab_routing() {
        // Given
        let navigator = ProductDetailNavigator(
            productRouting: CIABProductRoutingProvider(),
            coordinatorFactory: coordinatorFactory
        )

        // When
        _ = navigator.makeDestination(product: Self.aNonBookingProduct, isReadOnly: false)

        // Then
        #expect(coordinatorFactory.createdNativeCoordiantor)
        #expect(!coordinatorFactory.createdWebCoordiantor)
    }

    // MARK: - New booking type (bookable-service)

    @Test
    func new_booking_product_with_ciab_routing_directs_to_web_view() {
        // Given
        let navigator = ProductDetailNavigator(
            productRouting: CIABProductRoutingProvider(),
            coordinatorFactory: coordinatorFactory
        )

        // When
        _ = navigator.makeDestination(product: Self.aNewBookingProduct, isReadOnly: false)

        // Then
        #expect(coordinatorFactory.createdWebCoordiantor)
        #expect(!coordinatorFactory.createdNativeCoordiantor)
    }

    @Test
    func new_booking_product_with_standard_routing_directs_to_native_view() {
        // Given
        let navigator = ProductDetailNavigator(
            productRouting: StandardProductRoutingProvider(),
            coordinatorFactory: coordinatorFactory
        )

        // When
        _ = navigator.makeDestination(product: Self.aNewBookingProduct, isReadOnly: false)

        // Then
        #expect(coordinatorFactory.createdNativeCoordiantor)
        #expect(!coordinatorFactory.createdWebCoordiantor)
    }

    // MARK: - Legacy booking type

    @Test(arguments: [
        StandardProductRoutingProvider() as ProductRoutingProviding,
        CIABProductRoutingProvider() as ProductRoutingProviding
    ])
    func legacy_booking_product_directs_to_web_view_regardless_of_routing(routing: ProductRoutingProviding) {
        // Given
        let navigator = ProductDetailNavigator(
            productRouting: routing,
            coordinatorFactory: coordinatorFactory
        )

        // When
        _ = navigator.makeDestination(product: Self.aLegacyBookingProduct, isReadOnly: false)

        // Then
        #expect(coordinatorFactory.createdWebCoordiantor)
        #expect(!coordinatorFactory.createdNativeCoordiantor)
    }
}
