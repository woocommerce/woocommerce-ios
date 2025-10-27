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
        let bookings = try await remote.loadAllBookings(for: sampleSiteID, order: .descending)

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
            _ = try await remote.loadAllBookings(for: sampleSiteID, order: .descending)
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
                                             searchQuery: searchQuery,
                                             order: .ascending)

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        let parameters = request.parameters

        #expect((parameters["page"] as? String) == "2")
        #expect((parameters["per_page"] as? String) == "50")
        #expect((parameters["start_date_before"] as? String) == startDateBefore)
        #expect((parameters["start_date_after"] as? String) == startDateAfter)
        #expect((parameters["search"] as? String) == searchQuery)
        #expect((parameters["order"] as? String) == "asc")
    }

    @Test func test_loadAllBookings_omits_nil_parameters() async throws {
        // Given
        let remote = BookingsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "bookings", filename: "booking-list")

        // When
        _ = try await remote.loadAllBookings(for: sampleSiteID,
                                             startDateBefore: nil,
                                             startDateAfter: nil,
                                             searchQuery: nil,
                                             order: .descending)

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        let parameters = request.parameters

        #expect(parameters["start_date_before"] == nil)
        #expect(parameters["start_date_after"] == nil)
        #expect(parameters["s"] == nil)
        #expect(parameters["page"] != nil)
        #expect(parameters["per_page"] != nil)
        #expect(parameters["order"] != nil)
    }

    @Test func test_fetchResource_properly_returns_parsed_resource() async throws {
        // Given
        let remote = BookingsRemote(network: network)
        let resourceID: Int64 = 22
        network.simulateResponse(requestUrlSuffix: "resources/team-members/\(resourceID)", filename: "booking-resource")

        // When
        let resource = try await remote.fetchResource(resourceID: resourceID, siteID: sampleSiteID)

        // Then
        let unwrappedResource = try #require(resource)
        #expect(unwrappedResource.resourceID == 22)
        #expect(unwrappedResource.name == "Joel (Sample resource)")
        #expect(unwrappedResource.quantity == 1)
        #expect(unwrappedResource.role == "")
        #expect(unwrappedResource.email == "")
        #expect(unwrappedResource.phoneNumber == "")
        #expect(unwrappedResource.imageID == 0)
        #expect(unwrappedResource.imageURL == "")
        #expect(unwrappedResource.description == "")
        #expect(unwrappedResource.siteID == sampleSiteID)
    }

    @Test func test_fetchResource_properly_relays_networking_errors() async {
        // Given
        let remote = BookingsRemote(network: network)

        // Then
        await #expect(throws: NetworkError.notFound()) {
            _ = try await remote.fetchResource(resourceID: 22, siteID: sampleSiteID)
        }
    }

    @Test func test_updateBooking_ignores_nil_dates_in_response() async throws {
        // Given
        let remote = BookingsRemote(network: network)
        let bookingID: Int64 = 206
        network.simulateResponse(requestUrlSuffix: "bookings/\(bookingID)", filename: "booking-no-create-update-dates")

        // When
        let booking = try await remote.updateBooking(
            from: sampleSiteID,
            bookingID: bookingID,
            attendanceStatus: .noShow,
        )

        // Then
        #expect(booking?.dateCreated == nil)
        #expect(booking?.dateModified == nil)
        #expect(booking?.id == bookingID)
    }
}
