import APIMocks
import UITestsFoundation
import XCTest

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
        "variable": "products_add_new_variable_2131",
        "grouped": "products_add_new_grouped_2130",
        "external": "products_add_new_external_2132"
    ]

    static func getMockData(filename: String) -> Data {
        try! APIMocks.loadMockData(filename: filename)
    }

    // All "readScreenData()" methods are intentionally separated. Not a common method because it could end up being one with a long list of
    // parameters (almost every line is a different value) with different return types.
    static func readProductsData() throws -> [ProductData] {
        let originalData = try JSONDecoder().decode(ProductMock.self, from: getMockData(filename: "products"))
        var updatedData = originalData.response.jsonBody.data

        for index in 0..<updatedData.count {
            let rawStockStatus = updatedData[index].stock_status
            let humanReadableStockStatus = GetMocks.init().stockStatus[rawStockStatus]!
            updatedData[index].stock_status = humanReadableStockStatus
        }

        return updatedData
    }

    static func readNewProductData(productType: String) throws -> ProductData {
        let originalData = try JSONDecoder().decode(NewProductMock.self, from: getMockData(filename: file[productType]!))

        return try XCTUnwrap(originalData.response.jsonBody.data)
    }

    static func readReviewsData() throws -> [ReviewData] {
        let originalData = try JSONDecoder().decode(ReviewMock.self, from: getMockData(filename: "products_reviews_all"))
        var updatedData = originalData.response.jsonBody.data

        for index in 0..<updatedData.count {
            let productId = updatedData[index].product_id
            let productName = GetMocks.init().productName[productId]!
            updatedData[index].product_name = productName
        }

        return updatedData
    }

    static func readOrdersData() throws -> [OrderData] {
        let originalData = try JSONDecoder().decode(OrdersMock.self, from: getMockData(filename: "orders_any"))
        var updatedData = originalData.response.jsonBody.data

        for index in 0..<updatedData.count {
            let total = updatedData[index].total
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            numberFormatter.locale = Locale(identifier: "en_US")

            let formattedNumber = numberFormatter.string(from: NSNumber(value: Double(total)!))
            updatedData[index].total = formattedNumber!
        }

        return updatedData
    }

    static func readSingleOrderData() throws -> OrderData {
        let originalData = try JSONDecoder().decode(OrderMock.self, from: getMockData(filename: "orders_3337"))
        return try XCTUnwrap(originalData.response.jsonBody.data)
    }
}
