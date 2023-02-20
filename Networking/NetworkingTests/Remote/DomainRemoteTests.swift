import XCTest
import TestKit
@testable import Networking

final class DomainRemoteTests: XCTestCase {
    /// Mock network wrapper.
    private var network: MockNetwork!

    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    // MARK: - `loadFreeDomainSuggestions`

    func test_loadFreeDomainSuggestions_returns_suggestions_on_success() async throws {
        // Given
        let remote = DomainRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "domains/suggestions", filename: "domain-suggestions")

        // When
        let suggestions = try await remote.loadFreeDomainSuggestions(query: "domain")

        // Then
        XCTAssertEqual(suggestions, [
            .init(name: "domaintestingtips.wordpress.com", isFree: true),
            .init(name: "domaintestingtoday.wordpress.com", isFree: true),
        ])
    }

    func test_loadFreeDomainSuggestions_returns_error_on_empty_response() async throws {
        // Given
        let remote = DomainRemote(network: network)

        await assertThrowsError({_ = try await remote.loadFreeDomainSuggestions(query: "domain")}, errorAssert: { ($0 as? NetworkError) == .notFound })
    }

    // MARK: - `loadPaidDomainSuggestions`

    func test_loadPaidDomainSuggestions_returns_suggestions_on_success() async throws {
        // Given
        let remote = DomainRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "domains/suggestions", filename: "domain-suggestions-paid")

        // When
        let suggestions = try await remote.loadPaidDomainSuggestions(query: "domain")

        // Then
        XCTAssertEqual(suggestions, [
            .init(name: "color.bar", productID: 356, supportsPrivacy: true),
            .init(name: "color.ink", productID: 359, supportsPrivacy: true)
        ])
    }

    func test_loadPaidDomainSuggestions_returns_error_on_empty_response() async throws {
        // Given
        let remote = DomainRemote(network: network)

        await assertThrowsError({_ = try await remote.loadPaidDomainSuggestions(query: "domain")}, errorAssert: { ($0 as? NetworkError) == .notFound })
    }

    // MARK: - `loadDomainProducts`

    func test_loadDomainProducts_returns_products_on_success() async throws {
        // Given
        let remote = DomainRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "products", filename: "domain-products")

        // When
        // Products are in random order because of the product name mapping.
        // They are sorted here to ensure the same order for unit testing.
        let products = try await remote.loadDomainProducts().sorted(by: { $0.productID < $1.productID })

        // Then
        XCTAssertEqual(products, [
            .init(productID: 355, term: "year", cost: "US$15.00", saleCost: "US$3.90"),
            .init(productID: 356, term: "year", cost: "US$60.00", saleCost: nil)
        ])
    }

    func test_loadDomainProducts_returns_error_on_empty_response() async throws {
        // Given
        let remote = DomainRemote(network: network)

        await assertThrowsError({_ = try await remote.loadDomainProducts()}, errorAssert: { ($0 as? NetworkError) == .notFound })
    }

    // MARK: - `loadDomains`

    func test_loadDomains_returns_domains_on_success() async throws {
        // Given
        let remote = DomainRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "domains", filename: "site-domains")

        // When
        let domains = try await remote.loadDomains(siteID: 23)

        // Then
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        let renewalDate = try XCTUnwrap(dateFormatter.date(from: "December 10, 2023"))
        assertEqual(domains, [
            .init(name: "crabparty.wpcomstaging.com", isPrimary: true, isWPCOMStagingDomain: true, type: .wpcom),
            .init(name: "crabparty.com", isPrimary: false, isWPCOMStagingDomain: false, type: .mapping, renewalDate: renewalDate),
            .init(name: "crabparty.wordpress.com", isPrimary: false, isWPCOMStagingDomain: false, type: .wpcom)
        ])
    }

    func test_loadDomains_returns_error_on_empty_response() async throws {
        // Given
        let remote = DomainRemote(network: network)

        await assertThrowsError({_ = try await remote.loadDomains(siteID: 23)}, errorAssert: { ($0 as? NetworkError) == .notFound })
    }

    // MARK: - `loadDomainContactInfo`

    func test_loadDomainContactInfo_returns_contact_info_on_success() async throws {
        // Given
        let remote = DomainRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "me/domain-contact-information", filename: "domain-contact-info")

        // When
        let contactInfo = try await remote.loadDomainContactInfo()

        // Then
        XCTAssertEqual(contactInfo, .init(firstName: "Woo",
                                          lastName: "Merch",
                                          organization: nil,
                                          address1: "No 77",
                                          address2: nil,
                                          postcode: "94111",
                                          city: "SF",
                                          state: nil,
                                          countryCode: "US",
                                          phone: "+886.123456",
                                          email: "woo@merch.com"))
    }

    func test_loadDomainContactInfo_returns_error_on_empty_response() async throws {
        // Given
        let remote = DomainRemote(network: network)

        await assertThrowsError({ _ = try await remote.loadDomainContactInfo() }, errorAssert: { ($0 as? NetworkError) == .notFound })
    }

    // MARK: - `validateDomainContactInfo`

    func test_validateDomainContactInfo_returns_contact_info_on_success() async throws {
        // Given
        let remote = DomainRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "domain-contact-information/validate", filename: "validate-domain-contact-info-success")

        // When
        do {
            try await remote.validate(domainContactInfo: .fake(), domain: "")
        } catch {
            // Then
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_validateDomainContactInfo_returns_invalid_error_on_validation_failure() async throws {
        // Given
        let remote = DomainRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "domain-contact-information/validate", filename: "validate-domain-contact-info-failure")

        // When/Then
        let error = DomainContactInfoError.invalid(messages: [
            "There was an error validating your contact information. The field \"Last Name\" is not valid.",
            "There was an error validating your contact information. The field \"Phone\" is not valid."
        ])
        await assertThrowsError({ _ = try await remote.validate(domainContactInfo: .fake(), domain: "") },
                                errorAssert: { ($0 as? DomainContactInfoError) == error })
    }

    func test_validateDomainContactInfo_returns_error_on_empty_response() async throws {
        // Given
        let remote = DomainRemote(network: network)

        await assertThrowsError({_ = try await remote.validate(domainContactInfo: .fake(), domain: "")},
                                errorAssert: { ($0 as? NetworkError) == .notFound })
    }
}
