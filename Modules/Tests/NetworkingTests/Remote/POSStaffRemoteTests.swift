import Foundation
import Testing
@testable import Networking
@testable import NetworkingCore

struct POSStaffRemoteTests {
    /// Mock network to inject responses and capture issued requests.
    private let network = MockNetwork()

    private let sampleSiteID: Int64 = 1234

    // MARK: - Request shape

    @Test func fetchStaff_issues_a_get_to_the_wc_pos_v1_staff_endpoint() async throws {
        // Given
        let remote = POSStaffRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "staff", filename: "pos-staff")

        // When
        _ = try await remote.fetchStaff(siteID: sampleSiteID)

        // Then
        let request = try #require(network.requestsForResponseData.first as? JetpackRequest)
        #expect(request.wooApiVersion == .wcPosV1)
        #expect(request.method == .get)
        #expect(request.siteID == sampleSiteID)
        #expect(request.path == "staff")
    }

    // MARK: - Response parsing

    @Test func fetchStaff_parses_members_from_a_data_envelope_response() async throws {
        // Given
        let remote = POSStaffRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "staff", filename: "pos-staff")

        // When
        let staff = try await remote.fetchStaff(siteID: sampleSiteID)

        // Then
        #expect(staff.count == 3)

        let manager = try #require(staff.first)
        #expect(manager.userID == 12)
        #expect(manager.displayName == "Morgan Manager")
        #expect(manager.preset == .manager)
        #expect(manager.capabilities["woocommerce_pos_issue_refunds"] == true)
        #expect(manager.capabilities["woocommerce_pos_manage_staff"] == true)

        let pin = try #require(manager.pin)
        #expect(pin.algorithm == "pbkdf2-sha256")
        #expect(pin.iterations == 100000)
        #expect(pin.salt == "RkFLRS1URVNULVNBTFQtbm90LWEtcmVhbC1waW4tbWFuYWdlcg==")
        #expect(pin.hash == "RkFLRS1URVNULUhBU0gtbm90LWEtcmVhbC1waW4tbWFuYWdlcg==")
    }

    @Test func fetchStaff_parses_members_from_a_flat_array_response() async throws {
        // Given a direct REST response that is not wrapped in a `data` envelope
        let remote = POSStaffRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "staff", filename: "pos-staff-without-data-envelope")

        // When
        let staff = try await remote.fetchStaff(siteID: sampleSiteID)

        // Then
        #expect(staff.count == 2)
        #expect(staff.map { $0.userID } == [12, 34])

        let cashier = try #require(staff.last)
        #expect(cashier.preset == .cashier)
        #expect(cashier.capabilities == ["woocommerce_pos_process_sales": true])
    }

    @Test func fetchStaff_decodes_a_nil_pin_for_a_member_without_a_pin() async throws {
        // Given a response whose last member has `"pin": null`
        let remote = POSStaffRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "staff", filename: "pos-staff")

        // When
        let staff = try await remote.fetchStaff(siteID: sampleSiteID)

        // Then
        let admin = try #require(staff.last)
        #expect(admin.userID == 1)
        #expect(admin.preset == .admin)
        #expect(admin.pin == nil)
    }

    @Test func fetchStaff_returns_an_empty_list_for_an_empty_response() async throws {
        // Given
        let remote = POSStaffRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "staff", filename: "empty-data-array")

        // When
        let staff = try await remote.fetchStaff(siteID: sampleSiteID)

        // Then
        #expect(staff.isEmpty)
    }

    // MARK: - Error handling

    @Test func fetchStaff_relays_networking_errors() async throws {
        // Given no simulated response, so the network reports a not-found error
        let remote = POSStaffRemote(network: network)

        // When / Then
        await #expect(throws: NetworkError.notFound()) {
            _ = try await remote.fetchStaff(siteID: sampleSiteID)
        }
    }
}
