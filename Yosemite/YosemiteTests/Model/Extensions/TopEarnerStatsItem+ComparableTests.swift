import Codegen
import XCTest
@testable import Yosemite

final class TopEarnerStatsItem_ComparableTests: XCTestCase {
    func test_comparing_TopEarnerStatsItem_with_equal_quantity_is_by_total_amount() {
        // When
        let statsItemWithLowerTotal = TopEarnerStatsItem.fake().copy(quantity: 2, total: 3.5)
        let statsItemWithHigherTotal = TopEarnerStatsItem.fake().copy(quantity: 2, total: 3.6)

        // Then
        XCTAssertGreaterThan(statsItemWithHigherTotal, statsItemWithLowerTotal)
    }

    func test_comparing_TopEarnerStatsItem_with_different_quantity_is_by_quantity() {
        // When
        let statsItemWithLowerQuantity = TopEarnerStatsItem.fake().copy(quantity: 1, total: 3.7)
        let statsItemWithHigherQuantity = TopEarnerStatsItem.fake().copy(quantity: 2, total: 3.6)

        // Then
        XCTAssertGreaterThan(statsItemWithHigherQuantity, statsItemWithLowerQuantity)
    }
}
