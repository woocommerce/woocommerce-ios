import Testing
@testable import Networking

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
}
