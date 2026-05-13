import Foundation
import Testing
@testable import WooAIAssistant

@Suite(.timeLimit(.minutes(1)))
struct CardTelemetryFamilyMapperTests {

    @Test
    func test_family_forCardFamilyID_when_each_supported_family_then_never_maps_to_unknown() {
        // Given
        let supported: [CardFamilyID] = [.order, .product, .productVariation, .customer, .analyticsStats]

        // When
        let mapped = supported.map(CardTelemetryFamilyMapper.family(forCardFamilyID:))

        // Then
        #expect(!mapped.contains(.unknown))
    }

    @Test
    func test_family_forCardFamilyID_when_order_then_returns_order() {
        #expect(CardTelemetryFamilyMapper.family(forCardFamilyID: .order) == .order)
    }

    @Test
    func test_family_forCardFamilyID_when_product_then_returns_product() {
        #expect(CardTelemetryFamilyMapper.family(forCardFamilyID: .product) == .product)
    }

    @Test
    func test_family_forCardFamilyID_when_productVariation_then_returns_variation() {
        #expect(CardTelemetryFamilyMapper.family(forCardFamilyID: .productVariation) == .variation)
    }

    @Test
    func test_family_forCardFamilyID_when_customer_then_returns_customer() {
        #expect(CardTelemetryFamilyMapper.family(forCardFamilyID: .customer) == .customer)
    }

    @Test
    func test_family_forCardFamilyID_when_analyticsStats_then_returns_analyticsStats() {
        #expect(CardTelemetryFamilyMapper.family(forCardFamilyID: .analyticsStats) == .analyticsStats)
    }
}
