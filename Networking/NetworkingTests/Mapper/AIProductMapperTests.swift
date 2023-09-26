import XCTest
@testable import Networking

final class AIProductMapperTests: XCTestCase {
    private let siteID: Int64 = 123

    func test_it_maps_product_correctly_from_AI_json_response() throws {
        // Given
        let data = try retrieveGenerateProductResponse()
        let mapper = AIProductMapper(siteID: siteID,
                                     existingCategories: [.fake(), .fake()],
                                     existingTags: [.fake(), .fake()])

        // When
        let product = try mapper.map(response: data)

        // Then
        XCTAssertEqual(product.name, "Cookie")
        // swiftlint:disable line_length
        XCTAssertEqual(product.fullDescription, "Introducing Cookie, the ultimate crunchy and crispy treat that will satisfy your snacking cravings. Made with the finest ingredients, these irresistible cookies are baked to perfection, delivering a delightful texture with every bite. Whether you're enjoying them with a cup of tea or sharing them with friends, Cookie is the go-to snack for any casual occasion. Indulge in the mouthwatering flavors and experience a taste sensation that will leave you wanting more. Get your hands on Cookie today and discover why it's the ultimate snack companion.")
        XCTAssertEqual(product.shortDescription, "The ultimate crunchy and crispy treat that will satisfy your snacking cravings. Made with the finest ingredients, these irresistible cookies are baked to perfection, delivering a delightful texture with every bite. Indulge in the mouthwatering flavors of Cookie today!")
        // swiftlint:enable line_length
        XCTAssertFalse(product.virtual)
        XCTAssertEqual(product.weight, "0.2")
        XCTAssertEqual(product.dimensions.length, "15")
        XCTAssertEqual(product.dimensions.width, "10")
        XCTAssertEqual(product.dimensions.height, "5")
        XCTAssertEqual(product.price, "250")
    }

    func test_it_maps_product_correctly_when_no_shipping_info_available() throws {
        // Given
        let data = try retrieveGenerateProductNoShippingInfoResponse()
        let mapper = AIProductMapper(siteID: siteID,
                                     existingCategories: [.fake(), .fake()],
                                     existingTags: [.fake(), .fake()])

        // When
        let product = try mapper.map(response: data)

        // Then
        XCTAssertEqual(product.name, "Cookie")
        // swiftlint:disable line_length
        XCTAssertEqual(product.fullDescription, "Introducing Cookie, the ultimate crunchy and crispy treat that will satisfy your snacking cravings. Made with the finest ingredients, these irresistible cookies are baked to perfection, delivering a delightful texture with every bite. Whether you're enjoying them with a cup of tea or sharing them with friends, Cookie is the go-to snack for any casual occasion. Indulge in the mouthwatering flavors and experience a taste sensation that will leave you wanting more. Get your hands on Cookie today and discover why it's the ultimate snack companion.")
        XCTAssertEqual(product.shortDescription, "The ultimate crunchy and crispy treat that will satisfy your snacking cravings. Made with the finest ingredients, these irresistible cookies are baked to perfection, delivering a delightful texture with every bite. Indulge in the mouthwatering flavors of Cookie today!")
        // swiftlint:enable line_length
        XCTAssertFalse(product.virtual)
        XCTAssertEqual(product.weight, "")
        XCTAssertEqual(product.dimensions.length, "")
        XCTAssertEqual(product.dimensions.width, "")
        XCTAssertEqual(product.dimensions.height, "")
        XCTAssertEqual(product.price, "250")
    }

    func test_it_maps_product_with_matching_existing_categories() throws {
        // Given
        let biscuit: ProductCategory = .fake().copy(name: "Biscuits")
        let data = try retrieveGenerateProductResponse()
        let mapper = AIProductMapper(siteID: siteID,
                                     existingCategories: [biscuit, .fake(), .fake()],
                                     existingTags: [.fake(), .fake()])

        // When
        let product = try mapper.map(response: data)

        // Then
        XCTAssertEqual(product.categories, [biscuit])
    }

    func test_it_maps_product_with_matching_existing_tags() throws {
        // Given
        let food: ProductTag = .fake().copy(name: "Food")
        let data = try retrieveGenerateProductResponse()
        let mapper = AIProductMapper(siteID: siteID,
                                     existingCategories: [.fake(), .fake()],
                                     existingTags: [food, .fake(), .fake()])

        // When
        let product = try mapper.map(response: data)

        // Then
        XCTAssertEqual(product.tags, [food])
    }
}


// MARK: - Test Helpers
///
private extension AIProductMapperTests {
    func retrieveGenerateProductResponse() throws -> Data {
        guard let response = Loader.contentsOf("generate-product-success") else {
            throw FileNotFoundError()
        }

        return response
    }

    func retrieveGenerateProductNoShippingInfoResponse() throws -> Data {
        guard let response = Loader.contentsOf("generate-product-success-no-shipping-info") else {
            throw FileNotFoundError()
        }

        return response
    }

    struct FileNotFoundError: Error {}
}
