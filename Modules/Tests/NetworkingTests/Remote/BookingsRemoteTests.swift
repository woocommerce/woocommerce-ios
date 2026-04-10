import Foundation
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
        let startDateBefore = "2024-12-31T23:59:59Z"
        let startDateAfter = "2024-01-01T00:00:00Z"
        let searchQuery = "test search"
        let filters = BookingFilters(
            startDateBefore: startDateBefore,
            startDateAfter: startDateAfter
        )
        network.simulateResponse(requestUrlSuffix: "bookings", filename: "booking-list")

        // When
        _ = try await remote.loadAllBookings(for: sampleSiteID,
                                             pageNumber: 2,
                                             pageSize: 50,
                                             filters: filters,
                                             searchQuery: searchQuery,
                                             order: .ascending)

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        let parameters = request.parameters

        #expect((parameters["page"] as? String) == "2")
        #expect((parameters["per_page"] as? String) == "50")
        // Date filters are adjusted to be inclusive:
        // startDateBefore is adjusted +1 second: 2024-12-31T23:59:59 -> 2025-01-01T00:00:00
        #expect((parameters["start_date_before"] as? String) == "2025-01-01T00:00:00Z")
        // startDateAfter is adjusted -1 second: 2024-01-01T00:00:00 -> 2023-12-31T23:59:59
        #expect((parameters["start_date_after"] as? String) == "2023-12-31T23:59:59Z")
        #expect((parameters["search"] as? String) == searchQuery)
        #expect((parameters["order"] as? String) == "asc")
        #expect((parameters["orderby"] as? String) == "start_date")
    }

    @Test func test_loadAllBookings_omits_nil_parameters() async throws {
        // Given
        let remote = BookingsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "bookings", filename: "booking-list")

        // When
        _ = try await remote.loadAllBookings(for: sampleSiteID,
                                             filters: nil,
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
        #expect(unwrappedResource.role.isEmpty)
        #expect(unwrappedResource.email?.isEmpty == true)
        #expect(unwrappedResource.phoneNumber?.isEmpty == true)
        #expect(unwrappedResource.imageID == 0)
        #expect(unwrappedResource.imageURL?.isEmpty == true)
        #expect(unwrappedResource.description?.isEmpty == true)
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
            attendanceStatus: .attended,
            bookingStatus: nil,
            note: nil
        )

        // Then
        #expect(booking?.dateCreated == nil)
        #expect(booking?.dateModified == nil)
        #expect(booking?.id == bookingID)
    }

    @Test func test_updateBooking_sends_correct_parameters_for_attendance_status() async throws {
        // Given
        let remote = BookingsRemote(network: network)
        let bookingID: Int64 = 206
        network.simulateResponse(requestUrlSuffix: "bookings/\(bookingID)", filename: "booking-no-create-update-dates")

        // When
        _ = try await remote.updateBooking(
            from: sampleSiteID,
            bookingID: bookingID,
            attendanceStatus: .attended,
            bookingStatus: nil,
            note: nil
        )

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        let parameters = request.parameters

        #expect((parameters["attendance_status"] as? String) == "attended")
        #expect(parameters["status"] == nil)
    }

    @Test func test_updateBooking_sends_correct_parameters_for_booking_status() async throws {
        // Given
        let remote = BookingsRemote(network: network)
        let bookingID: Int64 = 206
        network.simulateResponse(requestUrlSuffix: "bookings/\(bookingID)", filename: "booking-no-create-update-dates")

        // When
        _ = try await remote.updateBooking(
            from: sampleSiteID,
            bookingID: bookingID,
            attendanceStatus: nil,
            bookingStatus: .confirmed,
            note: nil
        )

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        let parameters = request.parameters

        #expect(parameters["attendance_status"] == nil)
        #expect((parameters["status"] as? String) == "confirmed")
    }

    @Test func test_updateBooking_sends_correct_parameters_for_both_statuses() async throws {
        // Given
        let remote = BookingsRemote(network: network)
        let bookingID: Int64 = 206
        network.simulateResponse(requestUrlSuffix: "bookings/\(bookingID)", filename: "booking-no-create-update-dates")

        // When
        _ = try await remote.updateBooking(
            from: sampleSiteID,
            bookingID: bookingID,
            attendanceStatus: .unattended,
            bookingStatus: .paid,
            note: nil
        )

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        let parameters = request.parameters

        #expect((parameters["attendance_status"] as? String) == "unattended")
        #expect((parameters["status"] as? String) == "paid")
    }

    @Test func test_fetchResources_properly_returns_parsed_resources() async throws {
        // Given
        let remote = BookingsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "resources/team-members", filename: "booking-resource-list")

        // When
        let resources = try await remote.fetchResources(for: sampleSiteID)

        // Then
        #expect(resources.count == 2)
        let firstResource = try #require(resources.first)
        #expect(firstResource.resourceID == 22)
        #expect(firstResource.name == "Joel (Sample resource)")
        #expect(firstResource.quantity == 1)
        #expect(firstResource.siteID == sampleSiteID)
    }

    @Test func test_fetchResources_properly_relays_networking_errors() async {
        // Given
        let remote = BookingsRemote(network: network)

        // Then
        await #expect(throws: NetworkError.notFound()) {
            _ = try await remote.fetchResources(for: sampleSiteID)
        }
    }

    @Test func test_fetchResources_sends_correct_parameters() async throws {
        // Given
        let remote = BookingsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "resources/team-members", filename: "booking-resource-list")

        // When
        _ = try await remote.fetchResources(for: sampleSiteID, pageNumber: 3, pageSize: 100)

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        let parameters = request.parameters

        #expect((parameters["page"] as? String) == "3")
        #expect((parameters["per_page"] as? String) == "100")
    }

    @Test func test_fetchResources_sends_include_parameter_when_provided() async throws {
        // Given
        let remote = BookingsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "resources/team-members", filename: "booking-resource-list")

        // When
        _ = try await remote.fetchResources(for: sampleSiteID, pageNumber: 1, pageSize: 25, include: [10, 20, 30])

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        #expect((request.parameters["include"] as? String) == "10,20,30")
    }

    @Test func test_fetchResources_does_not_send_include_parameter_when_nil() async throws {
        // Given
        let remote = BookingsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "resources/team-members", filename: "booking-resource-list")

        // When
        _ = try await remote.fetchResources(for: sampleSiteID, pageNumber: 1, pageSize: 25)

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        #expect(request.parameters["include"] == nil)
    }

    @Test func test_updateBookingNote_sends_correct_parameters_for_booking_note() async throws {
        // Given
        let remote = BookingsRemote(network: network)
        let bookingID: Int64 = 206
        network.simulateResponse(requestUrlSuffix: "bookings/\(bookingID)", filename: "booking-no-create-update-dates")

        // When
        _ = try await remote.updateBooking(
            from: sampleSiteID,
            bookingID: bookingID,
            attendanceStatus: nil,
            bookingStatus: nil,
            note: "hello"
        )

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        let parameters = request.parameters

        #expect(parameters["attendance_status"] == nil)
        #expect(parameters["status"] == nil)
        #expect((parameters["note"] as? String) == "hello")
    }

    // MARK: - rescheduleBooking

    @Test func test_rescheduleBooking_sends_correct_parameters_with_resourceID() async throws {
        // Given
        let remote = BookingsRemote(network: network)
        let bookingID: Int64 = 206
        let startDate = Date(timeIntervalSince1970: 1776078000)
        let endDate = Date(timeIntervalSince1970: 1776081600)
        network.simulateResponse(requestUrlSuffix: "bookings/\(bookingID)", filename: "booking-no-create-update-dates")

        // When
        _ = try await remote.rescheduleBooking(
            from: sampleSiteID,
            bookingID: bookingID,
            startDate: startDate,
            endDate: endDate,
            resourceID: 42
        )

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        let parameters = request.parameters

        #expect((parameters["start"] as? Int64) == 1776078000)
        #expect((parameters["end"] as? Int64) == 1776081600)
        #expect((parameters["resource_id"] as? String) == "42")
    }

    @Test func test_rescheduleBooking_sends_correct_parameters_without_resourceID() async throws {
        // Given
        let remote = BookingsRemote(network: network)
        let bookingID: Int64 = 206
        let startDate = Date(timeIntervalSince1970: 1776078000)
        let endDate = Date(timeIntervalSince1970: 1776081600)
        network.simulateResponse(requestUrlSuffix: "bookings/\(bookingID)", filename: "booking-no-create-update-dates")

        // When
        _ = try await remote.rescheduleBooking(
            from: sampleSiteID,
            bookingID: bookingID,
            startDate: startDate,
            endDate: endDate,
            resourceID: nil
        )

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        let parameters = request.parameters

        #expect((parameters["start"] as? Int64) == 1776078000)
        #expect((parameters["end"] as? Int64) == 1776081600)
        #expect(parameters["resource_id"] == nil)
    }
}
