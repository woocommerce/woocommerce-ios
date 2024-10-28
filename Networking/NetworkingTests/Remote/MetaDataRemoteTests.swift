import XCTest
@testable import Networking

final class MetaDataRemoteTests: XCTestCase {

    /// Mock network wrapper.
    private var network: MockNetwork!

    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    func test_update_meta_data_for_product() async throws {
        // Given
        let siteID: Int64 = 1
        let parentID: Int64 = 1
        let type: MetaDataType = .product

        let remote = MetaDataRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products/\(parentID)", filename: "meta-data-products-orders-update")

        // When
        let metadata: [[String: Any?]] = [
            ["id": 1, "key": "lorem_key_1", "value": "Lorem ipsum"],
            ["id": 2, "key": "ipsum_key_2", "value": "dolor sit amet"],
            ["id": 3, "value": nil]
        ]

        let result = try await remote.updateMetaData(for: siteID, for: parentID, type: type, metadata: metadata)

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].metadataID, 1)
        XCTAssertEqual(result[0].key, "lorem_key_1")
        XCTAssertEqual(result[0].value, "Lorem ipsum")
        XCTAssertEqual(result[1].metadataID, 2)
        XCTAssertEqual(result[1].key, "ipsum_key_2")
        XCTAssertEqual(result[1].value, "dolor sit amet")
    }

    func test_update_meta_data_for_order() async throws {
        // Given
        let siteID: Int64 = 1
        let parentID: Int64 = 1
        let type: MetaDataType = .order

        let remote = MetaDataRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "orders/\(parentID)", filename: "meta-data-products-orders-update")

        // When
        let metadata: [[String: Any?]] = [
            ["id": 1, "key": "lorem_key_1", "value": "Lorem ipsum"],
            ["id": 2, "key": "ipsum_key_2", "value": "dolor sit amet"],
            ["id": 3, "value": nil]
        ]

        let result = try await remote.updateMetaData(for: siteID, for: parentID, type: type, metadata: metadata)

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].metadataID, 1)
        XCTAssertEqual(result[0].key, "lorem_key_1")
        XCTAssertEqual(result[0].value, "Lorem ipsum")
        XCTAssertEqual(result[1].metadataID, 2)
        XCTAssertEqual(result[1].key, "ipsum_key_2")
        XCTAssertEqual(result[1].value, "dolor sit amet")
    }

    // Helper method to load JSON data from file
    private func loadJSONData(from filename: String) -> Data? {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            return nil
        }
        return try? Data(contentsOf: url)
    }
}
