import XCTest
import TestKit
@testable import Networking

/// CustomerRemote Unit Tests
///
final class CustomerRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    let network = MockNetwork()

    /// Dummy Site ID
    let sampleSiteID: Int64 = 1234

    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    // MARK: - Get All Customers

    func test_getAllCustomers_returns_parsed_customers() throws {
        // Given
        let remote = CustomerRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "customers", filename: "customers-all")

        // When
        let result = try waitFor { promise in
            remote.getAllCustomers(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        let response = try XCTUnwrap(result.get())
        XCTAssertEqual(response.count, 2)

        let expectedId: Int64 = 25
        guard let expectedCustomer = response.first(where: { $0.userID == expectedId }) else {
            XCTFail("Customer with id \(expectedId) should exist")
            return
        }
        XCTAssertEqual(expectedCustomer.siteID, self.sampleSiteID)
        XCTAssertEqual(expectedCustomer.username, "john.doe")
    }

    func test_getAllCustomers_relays_networking_error() throws {
        // Given
        let remote = CustomerRemote(network: network)

        // When
        let result = try waitFor { promise in
            remote.getAllCustomers(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    // MARK: - Create Customer

    func test_createCustomers_returns_parsed_customer() throws {
        // Given
        let remote = CustomerRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "customers", filename: "customer")

        // When
        let customer = try sampleCustomer()
        let result = try waitFor { promise in
            remote.createCustomer(for: self.sampleSiteID, customer: customer) { result in
                promise(result)
            }
        }

        // Then
        let responseCustomer = try XCTUnwrap(result.get())
        XCTAssertEqual(responseCustomer, customer)
    }

    func test_createCustomer_relays_networking_error() throws {
        // Given
        let remote = CustomerRemote(network: network)

        // When
        let customer = try sampleCustomer()
        let result = try waitFor { promise in
            remote.createCustomer(for: self.sampleSiteID, customer: customer) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }
}


// MARK: - Private Helpers
//
private extension CustomerRemoteTests {

    func sampleCustomer() throws -> Customer {
        let billingAddress = Networking.Address(firstName: "John",
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

        let shippingAddress = Networking.Address(firstName: "John",
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
        let johnDoe = Networking.Customer(siteID: sampleSiteID,
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
