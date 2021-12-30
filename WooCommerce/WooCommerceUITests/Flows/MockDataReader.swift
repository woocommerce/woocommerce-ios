import UITestsFoundation
import XCTest
import Foundation

class GetMocks {

    var stockStatus = [
        "instock": "in stock",
        "onbackorder": "on back order",
        "outofstock": "out of stock"
    ]

    var productName = [
        2123: "malaya shades",
        2129: "akoya pearl shades",
        2130: "black coral shades",
        2131: "colorado shades",
        2132: "rose gold shades"
    ]

    static func getMockData(test: AnyClass, filename file: String) -> Data {
        let json = Bundle(for: test).url(forResource: file, withExtension: "json")!

        return try! Data(contentsOf: json)
    }

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
        let originalData = try JSONDecoder().decode(OrderMock.self, from: self.getMockData(test: OrdersTests.self, filename: "orders_any"))
        var updatedData = originalData.response.jsonBody.data

        for index in 0..<updatedData.count {
            let orderId = updatedData[index].id
            let orderTotal = updatedData[index].total
        }

        return updatedData
}
}

