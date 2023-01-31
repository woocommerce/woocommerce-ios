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
        XCTAssertEqual(customers.count, 4)
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
        XCTAssertEqual(customers[0].userID, 0)
        XCTAssertEqual(customers[0].name, "Matt The Unregistered")
        XCTAssertEqual(customers[1].userID, 1)
        XCTAssertEqual(customers[1].name, "John")
        XCTAssertEqual(customers[2].userID, 2)
        XCTAssertEqual(customers[2].name, "Paul")
        XCTAssertEqual(customers[3].userID, 3)
        XCTAssertEqual(customers[3].name, "John Doe")
    }

    func test_WCAnalyticsCustomer_array_maps_all_available_entities_if_response_has_no_data_envelope() {
        // Given
        let mapper = WCAnalyticsCustomerMapper(siteID: dummySiteID)
        var customers: [WCAnalyticsCustomer] = []

        XCTAssertEqual(customers.count, 0)

        // When
        guard let data = Loader.contentsOf("wc-analytics-customers-without-data") else {
            XCTFail("Data couldn't be loaded")
            return
        }
        customers = try! mapper.map(response: data)

        // Then
        XCTAssertEqual(customers.count, 2)
    }
}
