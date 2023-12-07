import XCTest
@testable import Networking

final class AIProductMapperTests: XCTestCase {
    private let siteID: Int64 = 123

    func test_it_maps_AIProduct_correctly_from_AI_json_response() async throws {
        // Given
        let data = try retrieveGenerateProductResponse()
        let mapper = AIProductMapper(siteID: siteID)

        // When
        let product = try await mapper.map(response: data)

        // Then
        XCTAssertEqual(product.name, "Cookie")
        // swiftlint:disable line_length
        XCTAssertEqual(product.description, "Introducing Cookie, the ultimate crunchy and crispy treat that will satisfy your snacking cravings. Made with the finest ingredients, these irresistible cookies are baked to perfection, delivering a delightful texture with every bite. Whether you're enjoying them with a cup of tea or sharing them with friends, Cookie is the go-to snack for any casual occasion. Indulge in the mouthwatering flavors and experience a taste sensation that will leave you wanting more. Get your hands on Cookie today and discover why it's the ultimate snack companion.")
        XCTAssertEqual(product.shortDescription, "The ultimate crunchy and crispy treat that will satisfy your snacking cravings. Made with the finest ingredients, these irresistible cookies are baked to perfection, delivering a delightful texture with every bite. Indulge in the mouthwatering flavors of Cookie today!")
        // swiftlint:enable line_length
        XCTAssertFalse(product.virtual)
        XCTAssertEqual(product.shipping.weight, "0.2")
        XCTAssertEqual(product.shipping.length, "15")
        XCTAssertEqual(product.shipping.width, "10")
        XCTAssertEqual(product.shipping.height, "5")
        XCTAssertEqual(product.price, "250")
    }

    func test_it_maps_AIProduct_correctly_when_no_shipping_info_available() async throws {
        // Given
        let data = try retrieveGenerateProductNoShippingInfoResponse()
        let mapper = AIProductMapper(siteID: siteID)

        // When
        let product = try await mapper.map(response: data)

        // Then
        XCTAssertEqual(product.name, "Cookie")
        // swiftlint:disable line_length
        XCTAssertEqual(product.description, "Introducing Cookie, the ultimate crunchy and crispy treat that will satisfy your snacking cravings. Made with the finest ingredients, these irresistible cookies are baked to perfection, delivering a delightful texture with every bite. Whether you're enjoying them with a cup of tea or sharing them with friends, Cookie is the go-to snack for any casual occasion. Indulge in the mouthwatering flavors and experience a taste sensation that will leave you wanting more. Get your hands on Cookie today and discover why it's the ultimate snack companion.")
        XCTAssertEqual(product.shortDescription, "The ultimate crunchy and crispy treat that will satisfy your snacking cravings. Made with the finest ingredients, these irresistible cookies are baked to perfection, delivering a delightful texture with every bite. Indulge in the mouthwatering flavors of Cookie today!")
        // swiftlint:enable line_length
        XCTAssertFalse(product.virtual)
        XCTAssertEqual(product.shipping.weight, "")
        XCTAssertEqual(product.shipping.length, "")
        XCTAssertEqual(product.shipping.width, "")
        XCTAssertEqual(product.shipping.height, "")
        XCTAssertEqual(product.price, "250")
    }

    func test_it_maps_AIProduct_correctly_when_no_weight_info_available() async throws {
        // Given
        let data = try retrieveGenerateProductNoWeightInfoResponse()
        let mapper = AIProductMapper(siteID: siteID)

        // When
        let product = try await mapper.map(response: data)

        // Then
        XCTAssertEqual(product.name, "Cookie")
        // swiftlint:disable line_length
        XCTAssertEqual(product.description, "Introducing Cookie, the ultimate crunchy and crispy treat that will satisfy your snacking cravings. Made with the finest ingredients, these irresistible cookies are baked to perfection, delivering a delightful texture with every bite. Whether you're enjoying them with a cup of tea or sharing them with friends, Cookie is the go-to snack for any casual occasion. Indulge in the mouthwatering flavors and experience a taste sensation that will leave you wanting more. Get your hands on Cookie today and discover why it's the ultimate snack companion.")
        XCTAssertEqual(product.shortDescription, "The ultimate crunchy and crispy treat that will satisfy your snacking cravings. Made with the finest ingredients, these irresistible cookies are baked to perfection, delivering a delightful texture with every bite. Indulge in the mouthwatering flavors of Cookie today!")
        // swiftlint:enable line_length
        XCTAssertFalse(product.virtual)
        XCTAssertEqual(product.shipping.weight, "")
        XCTAssertEqual(product.shipping.length, "15")
        XCTAssertEqual(product.shipping.width, "10")
        XCTAssertEqual(product.shipping.height, "5")
        XCTAssertEqual(product.price, "250")
    }

    func test_it_maps_AIProduct_correctly_when_no_dimensions_info_available() async throws {
        // Given
        let data = try retrieveGenerateProductNoDimensionsInfoResponse()
        let mapper = AIProductMapper(siteID: siteID)

        // When
        let product = try await mapper.map(response: data)

        // Then
        XCTAssertEqual(product.name, "Cookie")
        // swiftlint:disable line_length
        XCTAssertEqual(product.description, "Introducing Cookie, the ultimate crunchy and crispy treat that will satisfy your snacking cravings. Made with the finest ingredients, these irresistible cookies are baked to perfection, delivering a delightful texture with every bite. Whether you're enjoying them with a cup of tea or sharing them with friends, Cookie is the go-to snack for any casual occasion. Indulge in the mouthwatering flavors and experience a taste sensation that will leave you wanting more. Get your hands on Cookie today and discover why it's the ultimate snack companion.")
        XCTAssertEqual(product.shortDescription, "The ultimate crunchy and crispy treat that will satisfy your snacking cravings. Made with the finest ingredients, these irresistible cookies are baked to perfection, delivering a delightful texture with every bite. Indulge in the mouthwatering flavors of Cookie today!")
        // swiftlint:enable line_length
        XCTAssertFalse(product.virtual)
        XCTAssertEqual(product.shipping.weight, "0.2")
        XCTAssertEqual(product.shipping.length, "")
        XCTAssertEqual(product.shipping.width, "")
        XCTAssertEqual(product.shipping.height, "")
        XCTAssertEqual(product.price, "250")
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

    func retrieveGenerateProductNoWeightInfoResponse() throws -> Data {
        guard let response = Loader.contentsOf("generate-product-success-no-weight-info") else {
            throw FileNotFoundError()
        }

        return response
    }


    func retrieveGenerateProductNoDimensionsInfoResponse() throws -> Data {
        guard let response = Loader.contentsOf("generate-product-success-no-dimensions-info") else {
            throw FileNotFoundError()
        }

        return response
    }

    struct FileNotFoundError: Error {}
}
