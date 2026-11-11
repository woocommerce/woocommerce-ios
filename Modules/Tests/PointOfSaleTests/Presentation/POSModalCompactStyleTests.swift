import Testing
@testable import PointOfSale

struct POSModalCompactStyleTests {
    @Test func test_fullScreen_when_created_with_title_only_then_has_no_steps() {
        // Given
        let style = POSModalCompactStyle.fullScreen(title: "Card reader")

        // Then
        #expect(style == .fullScreen(title: "Card reader", hasSteps: false))
        #expect(style.fullScreenTitle == "Card reader")
        #expect(style.hasSteps == false)
    }

    @Test func test_fullScreen_when_created_with_steps_then_has_steps() {
        // Given
        let style = POSModalCompactStyle.fullScreen(title: "Barcode scanner", hasSteps: true)

        // Then
        #expect(style.fullScreenTitle == "Barcode scanner")
        #expect(style.hasSteps == true)
    }

    @Test func test_hasSteps_when_style_is_not_fullScreen_then_is_false() {
        #expect(POSModalCompactStyle.dialog.hasSteps == false)
        #expect(POSModalCompactStyle.bottomSheet.hasSteps == false)
        #expect(POSModalCompactStyle.dialog.fullScreenTitle == nil)
    }
}
