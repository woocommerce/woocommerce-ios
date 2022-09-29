import XCTest
@testable import Networking

class WCAnalyticsCustomerMapperTests: XCTestCase {
    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 123

    func test_WCAnalyticsCustomer_array_is_correctly_mapped_from_encoded_data() {
        // Given
        let mapper = WCAnalyticsCustomerMapper(siteID: dummySiteID)

        // When
        guard let data = Loader.contentsOf("wc-analytics-customers") else {
            XCTFail("Data couldn't be loaded")
            return
        }

        // Then
        XCTAssertNotNil(try? mapper.map(response: data))
    }

    func test_WCAnalyticsCustomer_array_maps_all_available_entities() {
        // Given
        let mapper = WCAnalyticsCustomerMapper(siteID: dummySiteID)
        var customers: [WCAnalyticsCustomer] = []

        XCTAssertEqual(customers.count, 0)

        // When
        guard let data = Loader.contentsOf("wc-analytics-customers") else {
            XCTFail("Data couldn't be loaded")
            return
        }
        customers = try! mapper.map(response: data)

        // Then
        XCTAssertEqual(customers.count, 2)
    }

    func test_WCAnalyticsCustomer_array_response_values_are_correctly_parsed() {
        // Given
        let mapper = WCAnalyticsCustomerMapper(siteID: dummySiteID)

        // When
        guard let data = Loader.contentsOf("wc-analytics-customers") else {
            XCTFail("Data couldn't be loaded")
            return
        }
        let customers = try! mapper.map(response: data)

        // Then
        XCTAssertEqual(customers[0].userID, 1)
        XCTAssertEqual(customers[0].name, "John")
        XCTAssertEqual(customers[1].userID, 2)
        XCTAssertEqual(customers[1].name, "Paul")
    }

    func test_WCAnalyticsCustomer_returns_no_entities_when_no_searchValue_is_provided() {
        // Given
        let mapper = WCAnalyticsCustomerMapper(siteID: dummySiteID)

        // When
        guard let data = Loader.contentsOf("wc-analytics-customers") else {
            XCTFail("Data couldn't be loaded")
            return
        }
        let customer = try! mapper.mapUniqueCustomer(response: data, searchValue: "")

        // Then
        XCTAssertEqual(customer?.userID, 0)
        XCTAssertEqual(customer?.name, "")
    }

    func test_WCAnalyticsCustomer_entity_is_correctly_mapped_from_encoded_data() {
        // Given
        let mapper = WCAnalyticsCustomerMapper(siteID: dummySiteID)

        // When
        guard let data = Loader.contentsOf("wc-analytics-customers") else {
            XCTFail("Data couldn't be loaded")
            return
        }
        let customer = try! mapper.mapUniqueCustomer(response: data, searchValue: "John")

        // Then
        XCTAssertNotNil(customer)
        XCTAssertEqual(customer?.userID, 1)
        XCTAssertEqual(customer?.name, "John")
    }
}
