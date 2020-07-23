import XCTest
@testable import Yosemite

/// LeaderboardProductParser unit tests
///
final class LeaderboardStatsConverterTest: XCTestCase {

    /// Sample site ID
    ///
    private let siteID: Int64 = 1234

    func testCorrectProductIDsFormLeaderboardOfTopProducts() {
        // Given
        let leaderboard = sampleLeaderboard(productIDs: Array((1...5)))

        // When
        let productIDs = LeaderboardStatsConverter.topProductsIDs(from: leaderboard)

        // Then
        XCTAssertEqual(productIDs, [1, 2, 3, 4, 5])
    }

    func testTopProductsAreMissingFromStoredProducts() {
        // Given
        let products = (2...4).map { MockProduct().product(siteID: siteID, productID: $0) }
        let leaderboard = sampleLeaderboard(productIDs: Array((1...5)))

        // When
        let missingIDs = LeaderboardStatsConverter.missingProductsIDs(from: leaderboard, in: products)

        // Then
        XCTAssertEqual(missingIDs.sorted(), [1, 5])
    }

    func testTopProductsAreNotMissingFromStoredProducts() {
        // Given
        let products = (1...5).map { MockProduct().product(siteID: siteID, productID: $0) }
        let leaderboard = sampleLeaderboard(productIDs: Array((1...5)))

        // When
        let missingIds = LeaderboardStatsConverter.missingProductsIDs(from: leaderboard, in: products)

        // Then
        XCTAssertTrue(missingIds.isEmpty)
    }

    func testConvertToProductsIntoStatItemsUsingStoredProducts() {
        // Given
        let products = (1...3).map { MockProduct().product(siteID: siteID, productID: $0) }
        let topProducts = sampleLeaderboard(productIDs: [1, 2, 3])

        // When
        let statItems = LeaderboardStatsConverter.topEearnerStatsItems(from: topProducts, using: products)

        // Then
        XCTAssertEqual(statItems.count, topProducts.rows.count)
        for ((topProduct, product), statItem) in zip(zip(topProducts.rows, products), statItems) {
            XCTAssertNotNil(statItem)
            XCTAssertEqual(statItem.productID, product.productID)
            XCTAssertEqual(statItem.productName, product.name)
            XCTAssertEqual(statItem.quantity, topProduct.quantity.value)
            XCTAssertEqual(statItem.price, Double(product.price))
            XCTAssertEqual(statItem.total, topProduct.total.value)
            XCTAssertEqual(statItem.imageUrl, product.images.first?.src)
        }
    }

    func testConvertTopProductsToStatItemsWithoutStoredProducts() {
        // Given
        let topProducts = sampleLeaderboard(productIDs: [1, 2, 3])

        // When
        let statItems = LeaderboardStatsConverter.topEearnerStatsItems(from: topProducts, using: [])

        // Then
        XCTAssertTrue(statItems.isEmpty)
    }
}

/// MARK: Test functions to generate sample data
///
private extension LeaderboardStatsConverterTest {

    func sampleLeaderboard(productIDs: [Int64]) -> Leaderboard {
        let topProducts = productIDs.map { sampleTopProduct(productID: $0) }
        return Leaderboard(id: "Top Products", label: "Top Products", rows: topProducts)
    }

    func sampleTopProduct(productID: Int64) -> LeaderboardRow {
        let productHtml = "<a href='https://store.com?products=\(productID)'>Product</a>"
        let subject = LeaderboardRowContent(display: productHtml, value: "Product")
        let quantity = LeaderboardRowContent(display: "2", value: 2)
        let total = LeaderboardRowContent(display: "10.50", value: 10.50)
        return LeaderboardRow(subject: subject, quantity: quantity, total: total)
    }
}
