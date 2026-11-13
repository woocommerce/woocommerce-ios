import Testing
@testable import PointOfSale

struct POSScaleToFitHeightModifierTests {
    @Test(arguments: [(400.0, 500.0), (500.0, 500.0), (0.0, 500.0)])
    func test_scale_when_content_fits_or_is_not_measured_then_returns_one(contentHeight: Double, availableHeight: Double) {
        // When
        let scale = POSScaleToFitHeightModifier.scale(contentHeight: contentHeight, availableHeight: availableHeight)

        // Then
        #expect(scale == 1)
    }

    @Test func test_scale_when_content_is_taller_than_available_then_returns_ratio() {
        // When
        let scale = POSScaleToFitHeightModifier.scale(contentHeight: 800, availableHeight: 600)

        // Then
        #expect(scale == 0.75)
    }
}
