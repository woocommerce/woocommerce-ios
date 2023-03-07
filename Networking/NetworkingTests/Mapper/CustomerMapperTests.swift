import XCTest
@testable import Networking

/// CustomerMapper Unit Tests
///
class CustomerMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 123

    /// Local file that holds Customer data representing the API endpoint
    ///
    private let filename: String = "customer"
    private let fileNameWithoutDataEnvelope = "customer-without-data"

    /// Verifies that the Customer object can be mapped fron the Encoded data
    ///
    func test_Customer_is_mapped_from_encoded_data() {
        // Given
        let mapper = CustomerMapper(siteID: dummySiteID)
        guard let data = Loader.contentsOf(filename) else {
            XCTFail("customer.json not found")
            return
        }

        // When
        let customer = try? mapper.map(response: data)

        // Then
        XCTAssertNotNil(mapper)
        XCTAssertNotNil(customer)
    }

    /// Verifies that all of the Customer response values are parsed correctly
    ///
    func test_Customer_response_values_are_correctly_parsed() throws {
        // Given
        guard let customer = try mapCustomer(from: filename) else {
            XCTFail()
            return
        }

        // Then
        XCTAssertNotNil(customer)
        XCTAssertEqual(customer.customerID, 25)
        XCTAssertEqual(customer.email, "john.doe@example.com")
        XCTAssertEqual(customer.firstName, "John")
        XCTAssertEqual(customer.lastName, "Doe")

        let dummyAddresses = [customer.shipping, customer.billing].compactMap({ $0 })
        XCTAssertEqual(dummyAddresses.count, 2)

        for address in dummyAddresses {
            XCTAssertEqual(address.firstName, "John")
            XCTAssertEqual(address.lastName, "Doe")
            XCTAssertEqual(address.company, "")
            XCTAssertEqual(address.address1, "969 Market")
            XCTAssertEqual(address.address2, "")
            XCTAssertEqual(address.city, "San Francisco")
            XCTAssertEqual(address.state, "CA")
            XCTAssertEqual(address.postcode, "94103")
            XCTAssertEqual(address.country, "US")
        }
    }

    /// Verifies that all of the Customer response values are parsed correctly
    ///
    func test_Customer_response_values_are_correctly_parsed_when_response_has_no_data_envelope() throws {
        // Given
        guard let customer = try mapCustomer(from: fileNameWithoutDataEnvelope) else {
            XCTFail()
            return
        }

        // Then
        XCTAssertNotNil(customer)
        XCTAssertEqual(customer.customerID, 25)
        XCTAssertEqual(customer.email, "john.doe@example.com")
        XCTAssertEqual(customer.firstName, "John")
        XCTAssertEqual(customer.lastName, "Doe")

        let dummyAddresses = [customer.shipping, customer.billing].compactMap({ $0 })
        XCTAssertEqual(dummyAddresses.count, 2)

        for address in dummyAddresses {
            XCTAssertEqual(address.firstName, "John")
            XCTAssertEqual(address.lastName, "Doe")
            XCTAssertEqual(address.company, "")
            XCTAssertEqual(address.address1, "969 Market")
            XCTAssertEqual(address.address2, "")
            XCTAssertEqual(address.city, "San Francisco")
            XCTAssertEqual(address.state, "CA")
            XCTAssertEqual(address.postcode, "94103")
            XCTAssertEqual(address.country, "US")
        }
    }
}

private extension CustomerMapperTests {
    /// Returns the CustomerMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapCustomer(from filename: String) throws -> Customer? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }
        return try! CustomerMapper(siteID: dummySiteID).map(response: response)
    }
}
