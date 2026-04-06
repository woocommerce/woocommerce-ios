import Testing
@testable import Networking
@testable import NetworkingCore


/// OrderFulfillmentListMapper Unit Tests
///
struct OrderFulfillmentListMapperTests {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 424242

    /// Dummy Order ID.
    ///
    private let dummyOrderID: Int64 = 99999999

    @Test func test_fulfillment_fields_are_properly_parsed_for_bare_array() throws {
        // Given
        let fulfillments = try mapFulfillments(from: "order_fulfillment_list")

        // Then
        #expect(fulfillments.count == 2)

        let first = try #require(fulfillments.first)
        #expect(first.siteID == dummySiteID)
        #expect(first.orderID == dummyOrderID)
        #expect(first.fulfillmentID == 42)
        #expect(first.status == "fulfilled")
        #expect(first.isFulfilled == true)
        #expect(first.dateUpdated != nil)
        #expect(first.dateFulfilled != nil)
        #expect(first.trackingNumber == "1Z999AA10123456784")
        #expect(first.shipmentProvider == "ups")
        #expect(first.trackingURL == "https://www.ups.com/track?tracknum=1Z999AA10123456784")

        let second = try #require(fulfillments.last)
        #expect(second.fulfillmentID == 43)
        #expect(second.status == "unfulfilled")
        #expect(second.isFulfilled == false)
        #expect(second.dateUpdated == nil)
        #expect(second.dateFulfilled == nil)
        #expect(second.trackingNumber == nil)
        #expect(second.shipmentProvider == nil)
        #expect(second.trackingURL == nil)
    }

    @Test func test_fulfillment_fields_are_properly_parsed_for_envelope_response() throws {
        // Given
        let fulfillments = try mapFulfillments(from: "order_fulfillment_list_envelope")

        // Then
        #expect(fulfillments.count == 1)

        let first = try #require(fulfillments.first)
        #expect(first.siteID == dummySiteID)
        #expect(first.orderID == dummyOrderID)
        #expect(first.fulfillmentID == 42)
        #expect(first.status == "fulfilled")
        #expect(first.trackingNumber == "1Z999AA10123456784")
        #expect(first.shipmentProvider == "ups")
    }

    @Test func test_fulfillment_fields_are_properly_parsed_for_empty_response() throws {
        // Given
        let fulfillments = try mapFulfillments(from: "order_fulfillment_list_empty")

        // Then
        #expect(fulfillments.isEmpty)
    }
}


// MARK: - Private Helpers
//
private extension OrderFulfillmentListMapperTests {

    func mapFulfillments(from filename: String) throws -> [OrderFulfillment] {
        guard let response = Loader.contentsOf(filename) else {
            throw MapperTestError.fixtureNotFound(filename)
        }

        return try OrderFulfillmentListMapper(siteID: dummySiteID, orderID: dummyOrderID).map(response: response)
    }
}


private enum MapperTestError: Error {
    case fixtureNotFound(String)
}
