import XCTest
@testable import WooCommerce

final class Double_RoundingTests: XCTestCase {
    // MARK: `shouldRoundUp: true`

    func test_rounding_up_10s_number_returns_the_next_higher_10s() {
        // Given
        let value: Double = 66

        // When
        let roundedValue = value.roundedToTheNextSamePowerOfTen(shouldRoundUp: true)

        // Then
        XCTAssertEqual(roundedValue, 70)
    }

    func test_rounding_up_100s_number_returns_the_next_higher_100s() {
        // Given
        let value: Double = 668

        // When
        let roundedValue = value.roundedToTheNextSamePowerOfTen(shouldRoundUp: true)

        // Then
        XCTAssertEqual(roundedValue, 700)
    }

    func test_rounding_up_1000s_number_returns_the_next_higher_1000s() {
        // Given
        let value: Double = 6687

        // When
        let roundedValue = value.roundedToTheNextSamePowerOfTen(shouldRoundUp: true)

        // Then
        XCTAssertEqual(roundedValue, 7000)
    }

    func test_rounding_up_10000s_number_returns_the_next_higher_10000s() {
        // Given
        let value: Double = 62251

        // When
        let roundedValue = value.roundedToTheNextSamePowerOfTen(shouldRoundUp: true)

        // Then
        XCTAssertEqual(roundedValue, 70000)
    }

    func test_rounding_up_100000s_number_returns_the_next_higher_100000s() {
        // Given
        let value: Double = 668788

        // When
        let roundedValue = value.roundedToTheNextSamePowerOfTen(shouldRoundUp: true)

        // Then
        XCTAssertEqual(roundedValue, 700000)
    }

    func test_rounding_up_1000000s_number_returns_the_next_higher_1000000s() {
        // Given
        let value: Double = 6687898

        // When
        let roundedValue = value.roundedToTheNextSamePowerOfTen(shouldRoundUp: true)

        // Then
        XCTAssertEqual(roundedValue, 7000000)
    }

    func test_rounding_up_negative_10s_number_returns_the_next_smaller_10s() {
        // Given
        let value: Double = -66

        // When
        let roundedValue = value.roundedToTheNextSamePowerOfTen(shouldRoundUp: true)

        // Then
        XCTAssertEqual(roundedValue, -60)
    }

    func test_rounding_up_0_number_returns_0() {
        // Given
        let value: Double = 0

        // When
        let roundedValue = value.roundedToTheNextSamePowerOfTen(shouldRoundUp: true)

        // Then
        XCTAssertEqual(roundedValue, 0)
    }

    func test_rounding_up_number_under_1_returns_1() {
        // Given
        let value: Double = 0.5

        // When
        let roundedValue = value.roundedToTheNextSamePowerOfTen(shouldRoundUp: true)

        // Then
        XCTAssertEqual(roundedValue, 1)
    }

    func test_rounding_up_number_under_10_returns_the_next_higher_integer() {
        // Given
        let value: Double = 3.14

        // When
        let roundedValue = value.roundedToTheNextSamePowerOfTen(shouldRoundUp: true)

        // Then
        XCTAssertEqual(roundedValue, 4)
    }

    // MARK: `shouldRoundUp: false`

    func test_rounding_down_10s_number_returns_the_next_lower_10s() {
        // Given
        let value: Double = 66

        // When
        let roundedValue = value.roundedToTheNextSamePowerOfTen(shouldRoundUp: false)

        // Then
        XCTAssertEqual(roundedValue, 60)
    }

    func test_rounding_down_100s_number_returns_the_next_lower_100s() {
        // Given
        let value: Double = 668

        // When
        let roundedValue = value.roundedToTheNextSamePowerOfTen(shouldRoundUp: false)

        // Then
        XCTAssertEqual(roundedValue, 600)
    }

    func test_rounding_down_1000s_number_returns_the_next_lower_1000s() {
        // Given
        let value: Double = 6687

        // When
        let roundedValue = value.roundedToTheNextSamePowerOfTen(shouldRoundUp: false)

        // Then
        XCTAssertEqual(roundedValue, 6000)
    }

    func test_rounding_down_10000s_number_returns_the_next_lower_10000s() {
        // Given
        let value: Double = 62251

        // When
        let roundedValue = value.roundedToTheNextSamePowerOfTen(shouldRoundUp: false)

        // Then
        XCTAssertEqual(roundedValue, 60000)
    }

    func test_rounding_down_100000s_number_returns_the_next_lower_100000s() {
        // Given
        let value: Double = 668788

        // When
        let roundedValue = value.roundedToTheNextSamePowerOfTen(shouldRoundUp: false)

        // Then
        XCTAssertEqual(roundedValue, 600000)
    }

    func test_rounding_down_1000000s_number_returns_the_next_lower_1000000s() {
        // Given
        let value: Double = 6687898

        // When
        let roundedValue = value.roundedToTheNextSamePowerOfTen(shouldRoundUp: false)

        // Then
        XCTAssertEqual(roundedValue, 6000000)
    }

    func test_rounding_down_negative_10s_number_returns_the_next_higher_10s() {
        // Given
        let value: Double = -66

        // When
        let roundedValue = value.roundedToTheNextSamePowerOfTen(shouldRoundUp: false)

        // Then
        XCTAssertEqual(roundedValue, -70)
    }

    func test_rounding_down_0_number_returns_0() {
        // Given
        let value: Double = 0

        // When
        let roundedValue = value.roundedToTheNextSamePowerOfTen(shouldRoundUp: false)

        // Then
        XCTAssertEqual(roundedValue, 0)
    }

    func test_rounding_down_number_under_1_returns_0() {
        // Given
        let value: Double = 0.5

        // When
        let roundedValue = value.roundedToTheNextSamePowerOfTen(shouldRoundUp: false)

        // Then
        XCTAssertEqual(roundedValue, 0)
    }

    func test_rounding_down_number_under_10_returns_the_floor_integer_value() {
        // Given
        let value: Double = 3.14

        // When
        let roundedValue = value.roundedToTheNextSamePowerOfTen(shouldRoundUp: false)

        // Then
        XCTAssertEqual(roundedValue, 3)
    }
}
