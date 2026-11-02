import Testing
@testable import StoreDesignSystem

@Suite struct StoreNoticeBannerAccessibilityTests {

    @Test func test_label_when_description_is_present_then_reads_title_and_description() {
        // Given
        let sut = StoreNoticeBannerAccessibility(title: "Orders synced",
                                                 description: "New order data is available.",
                                                 status: nil,
                                                 hasControls: false)

        // Then
        #expect(sut.label == "Orders synced, New order data is available.")
    }

    @Test func test_label_when_description_is_missing_then_reads_title_only() {
        // Given
        let sut = StoreNoticeBannerAccessibility(title: "USPS: API Outage", description: nil, status: "Error", hasControls: true)

        // Then
        #expect(sut.label == "USPS: API Outage")
        #expect(sut.status == "Error")
        #expect(sut.hasControls)
    }
}
