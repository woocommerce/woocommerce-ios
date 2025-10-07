import Testing
@testable import Networking
@testable import NetworkingCore

struct BookingsRemoteTests {

    private let network = MockNetwork()
    private let sampleSiteID: Int64 = 1234

    @Test func test_loadAllBookings_properly_returns_parsed_bookings() async throws {
        // Given
        let remote = BookingsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "bookings", filename: "booking-list")

        // When
        let bookings = try await remote.loadAllBookings(for: sampleSiteID)

        // Then
        #expect(bookings.count == 2)
        let firstBooking = try #require(bookings.first)
        #expect(firstBooking.bookingID == 80)
        #expect(firstBooking.allDay == false)
        #expect(firstBooking.bookingStatus == .unpaid)
        #expect(firstBooking.orderID == 79)
        #expect(firstBooking.productID == 23)
        #expect(firstBooking.customerID == 0)
        #expect(firstBooking.siteID == sampleSiteID)
        #expect(firstBooking.currency == "USD")
    }

    @Test func test_loadAllBookings_properly_relays_netwoking_errors() async {
        // Given
        let remote = BookingsRemote(network: network)

        // Then
        await #expect(throws: NetworkError.notFound()) {
            _ = try await remote.loadAllBookings(for: sampleSiteID)
        }
    }

    @Test func test_loadAllBookings_sends_correct_parameters() async throws {
        // Given
        let remote = BookingsRemote(network: network)
        let startDateBefore = "2024-12-31T23:59:59"
        let startDateAfter = "2024-01-01T00:00:00"
        let searchQuery = "test search"
        network.simulateResponse(requestUrlSuffix: "bookings", filename: "booking-list")

        // When
        _ = try await remote.loadAllBookings(for: sampleSiteID,
                                             pageNumber: 2,
                                             pageSize: 50,
                                             startDateBefore: startDateBefore,
                                             startDateAfter: startDateAfter,
                                             searchQuery: searchQuery)

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        let parameters = request.parameters

        #expect((parameters["page"] as? String) == "2")
        #expect((parameters["per_page"] as? String) == "50")
        #expect((parameters["start_date_before"] as? String) == startDateBefore)
        #expect((parameters["start_date_after"] as? String) == startDateAfter)
        #expect((parameters["s"] as? String) == searchQuery)
    }

    @Test func test_loadAllBookings_omits_nil_parameters() async throws {
        // Given
        let remote = BookingsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "bookings", filename: "booking-list")

        // When
        _ = try await remote.loadAllBookings(for: sampleSiteID,
                                             startDateBefore: nil,
                                             startDateAfter: nil,
                                             searchQuery: nil)

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        let parameters = request.parameters

        #expect(parameters["start_date_before"] == nil)
        #expect(parameters["start_date_after"] == nil)
        #expect(parameters["s"] == nil)
        #expect(parameters["page"] != nil)
        #expect(parameters["per_page"] != nil)
    }
}
