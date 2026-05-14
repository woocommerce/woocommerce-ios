import Testing
@testable import ParcelFittingCheck

@Suite("ParcelDimensions")
struct ParcelDimensionsTests {

    // MARK: - toCentimeters

    @Test func test_toCentimeters_when_inches_then_converts_correctly() {
        // Given
        let dims = ParcelDimensions(length: 10, width: 8, height: 5)

        // When
        let cm = dims.toCentimeters(from: .inches)

        // Then
        #expect(cm.length == 25)
        #expect(cm.width == 20)
        #expect(cm.height == 13)
    }

    @Test func test_toCentimeters_when_centimeters_then_identity() {
        // Given
        let dims = ParcelDimensions(length: 20, width: 15, height: 10)

        // When
        let cm = dims.toCentimeters(from: .centimeters)

        // Then
        #expect(cm.length == 20)
        #expect(cm.width == 15)
        #expect(cm.height == 10)
    }

    @Test func test_toCentimeters_when_meters_then_converts_correctly() {
        // Given
        let dims = ParcelDimensions(length: 1, width: 0.5, height: 0.25)

        // When
        let cm = dims.toCentimeters(from: .meters)

        // Then
        #expect(cm.length == 100)
        #expect(cm.width == 50)
        #expect(cm.height == 25)
    }
}
