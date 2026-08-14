import Testing
import Yosemite
@testable import WooCommerce

struct OrderCreationProductRestrictionsTests {
    @Test(arguments: [ProductType.subscription, .variableSubscription])
    func restriction_when_product_is_a_subscription_type_then_it_is_restricted_as_subscription(productType: ProductType) {
        // Given
        let product = Product.fake().copy(productTypeKey: productType.rawValue)

        // When / Then
        #expect(ProductRestriction.restriction(for: product) == .subscription)
    }

    @Test(arguments: [ProductType.booking, .legacyBooking])
    func restriction_when_product_is_a_bookable_type_then_it_is_restricted_as_bookable(productType: ProductType) {
        // Given
        let product = Product.fake().copy(productTypeKey: productType.rawValue)

        // When / Then
        #expect(ProductRestriction.restriction(for: product) == .bookable)
    }

    @Test(arguments: [ProductType.simple, .variable, .grouped, .affiliate, .bundle, .composite, .custom("something-else")])
    func restriction_when_product_type_is_supported_then_there_is_no_restriction(productType: ProductType) {
        // Given
        let product = Product.fake().copy(productTypeKey: productType.rawValue)

        // When / Then
        #expect(ProductRestriction.restriction(for: product) == nil)
    }

    @Test
    func every_restriction_explains_itself() {
        for restriction in ProductRestriction.allCases {
            #expect(restriction.reason.isNotEmpty)
        }
    }
}
