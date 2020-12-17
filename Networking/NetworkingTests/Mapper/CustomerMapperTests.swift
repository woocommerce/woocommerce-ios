import XCTest
@testable import Networking

/// CustomersMapper Unit Tests
///
final class CustomerMapperTests: XCTestCase {

    /// Site ID for testing.
    private let sampleSiteID: Int64 = 1234

    func test_customer_is_properly_parsed() throws {
        // Given
        let jsonData = try XCTUnwrap(Loader.contentsOf("customer"))

        // When
        let responseCustomer = try CustomerMapper(siteID: sampleSiteID).map(response: jsonData)

        // Then
        let johnDoe = try sampleCustomer()
        XCTAssertEqual(responseCustomer, johnDoe)
    }

    func test_customer_is_correctly_encoded() throws {
        // Given
        let johnDoe = try sampleCustomer()

        // When
        let encodedCustomerData = try CustomerMapper(siteID: sampleSiteID).map(customer: johnDoe)
        let customerDictionary = try JSONSerialization.jsonObject(with: encodedCustomerData) as? [String: Any]

        // Then
        XCTAssertEqual(customerDictionary?["first_name"] as? String, "John")
        let billingAddressDictionary = try XCTUnwrap(customerDictionary?["billing"] as? [String: Any])
        XCTAssertEqual(billingAddressDictionary["first_name"] as? String, "John")
    }
}


// MARK: - Private Helpers
//
private extension CustomerMapperTests {

    func sampleCustomer() throws -> Customer {
        let billingAddress = Address(firstName: "John",
                                     lastName: "Doe",
                                     company: "",
                                     address1: "969 Market",
                                     address2: "",
                                     city: "San Francisco",
                                     state: "CA",
                                     postcode: "94103",
                                     country: "US",
                                     phone: "(555) 555-5555",
                                     email: "john.doe@example.com")

        let shippingAddress = Address(firstName: "John",
                                      lastName: "Doe",
                                      company: "",
                                      address1: "969 Market",
                                      address2: "",
                                      city: "San Francisco",
                                      state: "CA",
                                      postcode: "94103",
                                      country: "US",
                                      phone: nil,
                                      email: nil)

        let johnDoeID: Int64 = 25
        let dateCreated = try XCTUnwrap(DateFormatter.Defaults.dateTimeFormatter.date(from: "2017-03-21T19:09:28"))
        let dateModified = try XCTUnwrap(DateFormatter.Defaults.dateTimeFormatter.date(from: "2017-03-21T19:09:30"))
        let johnDoe = Customer(siteID: sampleSiteID,
                               userID: johnDoeID,
                               dateCreated: dateCreated,
                               dateModified: dateModified,
                               email: "john.doe@example.com",
                               username: "john.doe",
                               firstName: "John",
                               lastName: "Doe",
                               avatarUrl: "https://secure.gravatar.com/avatar/8eb1b522f60d11fa897de1dc6351b7e8?s=96",
                               role: .customer,
                               isPaying: false,
                               billingAddress: billingAddress,
                               shippingAddress: shippingAddress)

        return johnDoe
    }
}
