import UITestsFoundation
import XCTest
import Foundation

class GetMocks {

    let stockStatus = [
        "instock": "in stock",
        "onbackorder": "on back order",
        "outofstock": "out of stock"
    ]

    let productName = [
        2123: "malaya shades",
        2129: "akoya pearl shades",
        2130: "black coral shades",
        2131: "colorado shades",
        2132: "rose gold shades"
    ]

    private static let file = [
        "physical": "products_add_new_physical_2129",
        "virtual": "products_add_new_virtual_2123",
        "variable": "products_add_new_variable_2131"
    ]

    static func getMockData(test: AnyClass, filename file: String) -> Data {
        let json = Bundle(for: test).url(forResource: file, withExtension: "json")!

        return try! Data(contentsOf: json)
    }

    // All "readScreenData()" methods are intentionally separated. Not a common method because it could end up being one with a long list of
    // parameters (almost every line is a different value) with different return types.
    static func readProductsData() throws -> [ProductData] {
        let originalData = try JSONDecoder().decode(ProductMock.self, from: self.getMockData(test: ProductsTests.self, filename: "products"))
        var updatedData = originalData.response.jsonBody.data

        for index in 0..<updatedData.count {
            let rawStockStatus = updatedData[index].stock_status
            let humanReadableStockStatus = GetMocks.init().stockStatus[rawStockStatus]!
            updatedData[index].stock_status = humanReadableStockStatus
        }

        return updatedData
    }

    static func readNewProductData(productType: String) throws -> ProductData {
        let originalData = try JSONDecoder().decode(NewProductMock.self, from: self.getMockData(test: ProductsTests.self, filename: file[productType]!))

        return try XCTUnwrap(originalData.response.jsonBody.data)
    }

    static func readReviewsData() throws -> [ReviewData] {
        let originalData = try JSONDecoder().decode(ReviewMock.self, from: self.getMockData(test: ReviewsTests.self, filename: "products_reviews_all"))
        var updatedData = originalData.response.jsonBody.data

        for index in 0..<updatedData.count {
            let productId = updatedData[index].product_id
            let productName = GetMocks.init().productName[productId]!
            updatedData[index].product_name = productName
        }

        return updatedData
    }

    static func readOrdersData() throws -> [OrderData] {
        let originalData = try JSONDecoder().decode(OrdersMock.self, from: self.getMockData(test: OrdersTests.self, filename: "orders_any"))
        var updatedData = originalData.response.jsonBody.data

        for index in 0..<updatedData.count {
            let total = updatedData[index].total
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal

            let formattedNumber = numberFormatter.string(from: NSNumber(value: Double(total)!))
            updatedData[index].total = formattedNumber!
        }

        return updatedData
    }

    static func readSingleOrderData() throws -> OrderData {
        let originalData = try JSONDecoder().decode(OrderMock.self, from: self.getMockData(test: OrdersTests.self, filename: "orders_3337"))
        return try XCTUnwrap(originalData.response.jsonBody.data)
    }
}
