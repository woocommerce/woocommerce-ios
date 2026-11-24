import Testing
import SwiftUI
@testable import PointOfSale

struct PointOfSaleItemListCardConstantsTests {
    private typealias Constants = PointOfSaleItemListCardConstants

    @Test func test_stacksContent_when_compact_and_accessibility_size_then_returns_true() {
        // When
        let stacks = Constants.stacksContent(metrics: .compact, dynamicTypeSize: .accessibility1)

        // Then
        #expect(stacks)
    }

    @Test(arguments: [
        (POSMetrics.compact, DynamicTypeSize.xxxLarge),
        (POSMetrics.regular, DynamicTypeSize.accessibility5)
    ])
    func test_stacksContent_when_not_compact_accessibility_size_then_returns_false(metrics: POSMetrics,
                                                                                  dynamicTypeSize: DynamicTypeSize) {
        // When
        let stacks = Constants.stacksContent(metrics: metrics, dynamicTypeSize: dynamicTypeSize)

        // Then
        #expect(!stacks)
    }

    @Test func test_imageSize_when_compact_and_accessibility_size_then_returns_unscaled_card_size() {
        // When
        let size = Constants.imageSize(metrics: .compact, scale: 3, dynamicTypeSize: .accessibility5)

        // Then
        #expect(size == POSMetrics.compact.productCardSize)
    }

    @Test func test_imageSize_when_regular_and_accessibility_size_then_caps_scaled_size() {
        // When
        let size = Constants.imageSize(metrics: .regular, scale: 3, dynamicTypeSize: .accessibility5)

        // Then
        #expect(size == POSMetrics.regular.productCardSize * Constants.maximumCardSizeMultiplier)
    }

    @Test func test_imageSize_when_compact_and_large_size_then_scales_card_size() {
        // When
        let size = Constants.imageSize(metrics: .compact, scale: 1.25, dynamicTypeSize: .xxxLarge)

        // Then
        #expect(size == POSMetrics.compact.productCardSize * 1.25)
    }
}
