import UITestsFoundation
import XCTest
import Foundation

class GetMocks {

    var stockStatus = [
        "instock": "in stock",
        "onbackorder": "on back order",
        "outofstock": "out of stock"
    ]

    static func getProductsMockDataContent(withFilename filename: String) -> Data {
        let json = Bundle(for: ProductsTests.self).url(forResource: filename, withExtension: "json")!

        return try! Data(contentsOf: json)
    }

    static func readProductsData() throws -> [ProductData] {
        let wrappedProductsData = try JSONDecoder().decode(MockFile.self, from: GetMocks.getProductsMockDataContent(withFilename: "products"))
        var unwrappedProductsData = wrappedProductsData.response.jsonBody.data

        for index in 0..<unwrappedProductsData.count {
            let rawStockStatus = unwrappedProductsData[index].stock_status
            let humanReadableStockStatus = GetMocks.init().stockStatus[rawStockStatus]!
            unwrappedProductsData[index].stock_status = humanReadableStockStatus
        }

        return unwrappedProductsData
    }
}
