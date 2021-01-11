import XCTest
@testable import Networking

final class ProductAttributeTermRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private var network: MockNetwork!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    /// Dummy attribute ID
    ///
    private let sampleAttributeID: Int64 = 32

    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    func test_load_ProductAttributeTerms_returns_parsed_terms() throws {
        // Given
        let remote = ProductAttributeTermRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products/attributes/\(sampleAttributeID)/terms", filename: "product-attribute-terms")

        // When
        let result: Result<[ProductAttributeTerm], Error> = try waitFor { promise in
            remote.loadProductAttributeTerms(for: self.sampleSiteID, attributeID: self.sampleAttributeID) { result in
                promise(result)
            }
        }

        // Then
        let terms = try result.get()
        XCTAssertEqual(terms.count, 3)
    }

    func test_load_ProductAttributeTerms_relays_networking_errors() throws {
        // Given
        let remote = ProductAttributeTermRemote(network: network)
        let expectedError = NSError(domain: #function, code: 0, userInfo: nil)
        network.simulateError(requestUrlSuffix: "products/attributes/\(sampleAttributeID)/terms", error: expectedError)

        // When
        let result: Result<[ProductAttributeTerm], Error> = try waitFor { promise in
            remote.loadProductAttributeTerms(for: self.sampleSiteID, attributeID: self.sampleAttributeID) { result in
                promise(result)
            }
        }

        // Then
        let error = try XCTUnwrap(result.failure) as NSError
        XCTAssertEqual(expectedError, error)
    }
}
