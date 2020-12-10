import XCTest
@testable import Networking

/// CustomersListMapper Unit Tests
///
final class CustomersListMapperTests: XCTestCase {
    /// Site ID for testing.
    private let sampleSiteID: Int64 = 1234

    func test_customers_list_is_properly_parsed() throws {
        // Given
        let jsonData = try XCTUnwrap(Loader.contentsOf("customers-all"))

        // When
        let response = try CustomersListMapper(siteID: sampleSiteID).map(response: jsonData)

        // Then
        XCTAssertEqual(response.count, 2)

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
                               gravatarUrl: "https://secure.gravatar.com/avatar/8eb1b522f60d11fa897de1dc6351b7e8?s=96",
                               isPaying: false,
                               billingAddress: billingAddress,
                               shippingAddress: shippingAddress)

        guard let expectedCustomer = response.first(where: { $0.userID == johnDoeID }) else {
            XCTFail("Customer with id \(johnDoeID) should exist")
            return
        }
        XCTAssertEqual(expectedCustomer, johnDoe)
    }
}
