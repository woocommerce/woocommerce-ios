import XCTest
import TestKit
@testable import Networking

/// ProductAttributesRemoteTests
///
final class ProductAttributesRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private var network: MockNetwork!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    // MARK: - Load all product attributes tests

    /// Verifies that loadAllProductAttributes properly parses the `product-attributes-all` sample response.
    ///
    func test_loadAllProductAttributes_properly_returns_parsed_productAttributes() throws {
        // Given
        let remote = ProductAttributesRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products/attributes", filename: "product-attributes-all")

        // When
        let result = waitFor { promise in
            remote.loadAllProductAttributes(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        let expectedResult = [ProductAttribute(siteID: sampleSiteID, attributeID: 1, name: "Color", position: 0, visible: true, variation: true, options: []),
                              ProductAttribute(siteID: sampleSiteID, attributeID: 2, name: "Size", position: 0, visible: true, variation: true, options: [])]

        let response = try XCTUnwrap(result.get())
        XCTAssertEqual(response, expectedResult)
        XCTAssertEqual(response.count, 2)
    }

    /// Verifies that loadAllProductAttributes properly relays Networking Layer errors.
    ///
    func test_loadAllProductAttributes_properly_relays_netwoking_errors() throws {
        // Given
        let remote = ProductAttributesRemote(network: network)

        // When
        let result = waitFor { promise in
            remote.loadAllProductAttributes(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNil(try? result.get())
        XCTAssertNotNil(result.failure)
    }

    // MARK: - Create a product attribute tests

    /// Verifies that createProductAttribute properly parses the `product-attribute-create` sample response.
    ///
    func test_createProductAttribute_properly_returns_parsed_productAttribute() throws {
        // Given
        let remote = ProductAttributesRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products/attributes", filename: "product-attribute-create")

        // When
        let result = waitFor { promise in
            remote.createProductAttribute(for: self.sampleSiteID, name: "Color") { result in
                promise(result)
            }
        }

        // Then
        let response = try XCTUnwrap(result.get())
        XCTAssertEqual(response.name, "Color")
        XCTAssertNil(result.failure)
    }

    /// Verifies that createProductAttribute properly relays Networking Layer errors.
    ///
    func test_createProductAttribute_properly_relays_netwoking_errors() throws {
        // Given
        let remote = ProductAttributesRemote(network: network)

        // When
        let result = waitFor { promise in
            remote.createProductAttribute(for: self.sampleSiteID, name: "Color") { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNil(try? result.get())
        XCTAssertNotNil(result.failure)
    }

    // MARK: - Update a product attribute tests

    /// Verifies that updateProductAttribute properly parses the `product-attribute-update` sample response.
    ///
    func test_updateProductAttribute_properly_returns_parsed_productAttribute() throws {
        // Given
        let defaultProductAttributeID: Int64 = 1
        let remote = ProductAttributesRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products/attributes/\(defaultProductAttributeID)", filename: "product-attribute-update")

        // When
        let result = waitFor { promise in
            remote.updateProductAttribute(for: self.sampleSiteID, productAttributeID: defaultProductAttributeID, name: "Color") { result in
                promise(result)
            }
        }

        // Then
        let response = try XCTUnwrap(result.get())
        XCTAssertEqual(response.name, "Color")
        XCTAssertNil(result.failure)
    }

    /// Verifies that updateProductAttribute properly relays Networking Layer errors.
    ///
    func test_updateProductAttribute_properly_relays_netwoking_errors() throws {
        // Given
        let defaultProductAttributeID: Int64 = 1
        let remote = ProductAttributesRemote(network: network)

        // When
        let result = waitFor { promise in
            remote.updateProductAttribute(for: self.sampleSiteID, productAttributeID: defaultProductAttributeID, name: "Color") { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNil(try? result.get())
        XCTAssertNotNil(result.failure)
    }

    // MARK: - Delete a product attribute tests

    /// Verifies that deleteProductAttribute properly parses the `product-attribute-delete` sample response.
    ///
    func test_deleteProductAttribute_properly_returns_parsed_productAttribute() throws {
        // Given
        let defaultProductAttributeID: Int64 = 1
        let remote = ProductAttributesRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products/attributes/\(defaultProductAttributeID)", filename: "product-attribute-delete")

        // When
        let result = waitFor { promise in
            remote.deleteProductAttribute(for: self.sampleSiteID, productAttributeID: defaultProductAttributeID) { result in
                promise(result)
            }
        }

        // Then
        let response = try XCTUnwrap(result.get())
        XCTAssertEqual(response.name, "Size")
        XCTAssertNil(result.failure)
    }

    /// Verifies that deleteProductAttribute properly relays Networking Layer errors.
    ///
    func test_deleteProductAttribute_properly_relays_netwoking_errors() throws {
        // Given
        let defaultProductAttributeID: Int64 = 1
        let remote = ProductAttributesRemote(network: network)

        // When
        let result = waitFor { promise in
            remote.deleteProductAttribute(for: self.sampleSiteID, productAttributeID: defaultProductAttributeID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertNil(try? result.get())
        XCTAssertNotNil(result.failure)
    }

}
