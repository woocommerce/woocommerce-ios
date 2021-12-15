import UITestsFoundation
import XCTest
import Foundation

class GetMocks {

    struct MockFile: Codable {
        let response: ResponseData
    }

    struct ResponseData: Codable {
        let status: Int
        let jsonBody: BodyData
    }

    struct BodyData: Codable {
        let data: [ProductData]
    }

    struct ProductData: Codable {
        let id: Int
        let name: String
        let stock_status: String
        let regular_price: String
    }

    static func getProductsMockedDataContent(withFilename filename: String) -> Data {
        let json = Bundle(for: ProductsTests.self).url(forResource: filename, withExtension: "json")!

        return try! Data(contentsOf: json)
    }

    static func readProductsData() throws -> MockFile {
        return try! JSONDecoder().decode(MockFile.self, from: GetMocks.getProductsMockedDataContent(withFilename: "products"))
    }
}
