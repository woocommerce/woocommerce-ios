import XCTest
@testable import Networking

final class BlazeRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private var network: MockNetwork!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    // MARK: - Create campaign

    func test_createCampaign_returns_successfully() async throws {
        // Given
        let remote = BlazeRemote(network: network)
        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1.1/campaigns"

        network.simulateResponse(requestUrlSuffix: suffix, filename: "blaze-create-campaign-success")

        // When
        try await remote.createCampaign(.fake(), siteID: sampleSiteID)

        // Then
        // No error
    }

    func test_createCampaign_sends_correct_parameters() async throws {
        // Given
        let remote = BlazeRemote(network: network)
        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1.1/campaigns"

        network.simulateResponse(requestUrlSuffix: suffix, filename: "blaze-create-campaign-success")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let startDateString = "2023-12-05"
        let startDate = try XCTUnwrap(dateFormatter.date(from: startDateString))

        let endDateString = "2023-12-11"
        let endDate = try XCTUnwrap(dateFormatter.date(from: endDateString))

        let mainImage = CreateBlazeCampaign.Image(url: "https://example.com/wp-content/uploads/2023/06/0_1-2.png?quality=80&strip=info&w=1500",
                                                  mimeType: "image/png")
        let targeting = BlazeTargetOptions(locations: [29211, 42546],
                                           languages: ["en", "de"],
                                           devices: ["mobile"],
                                           pageTopics: ["IAB3", "IAB4"])
        let campaign = CreateBlazeCampaign.fake().copy(origin: "WooMobile",
                                                       originVersion: "1.0.1",
                                                       paymentMethodID: "payment-method-id-123",
                                                       startDate: startDate,
                                                       endDate: endDate,
                                                       timeZone: "America/New_York",
                                                       totalBudget: 35.00,
                                                       siteName: "Unleash Your Brain's Potential",
                                                       textSnippet: "Discover the power of computer neural networks in unlocking your brain's full potential.",
                                                       targetUrl: "https://example.com/2023/06/25/unlocking-the-secrets-of-computer-neural-networks/",
                                                       urlParams: "var1=val2&var2=val2",
                                                       mainImage: mainImage,
                                                       targeting: targeting,
                                                       targetUrn: "urn:wpcom:post:191174658:47",
                                                       type: "product")

        // When
        _ = try await remote.createCampaign(campaign, siteID: sampleSiteID)

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.first as? DotcomRequest)
        XCTAssertEqual(request.parameters?["origin"] as? String, campaign.origin)
        XCTAssertEqual(request.parameters?["origin_version"] as? String, campaign.originVersion)
        XCTAssertEqual(request.parameters?["payment_method_id"] as? String, campaign.paymentMethodID)
        XCTAssertEqual(request.parameters?["start_date"] as? String, startDateString)
        XCTAssertEqual(request.parameters?["end_date"] as? String, endDateString)
        XCTAssertEqual(request.parameters?["time_zone"] as? String, campaign.timeZone)
        XCTAssertEqual(request.parameters?["total_budget"] as? Double, campaign.totalBudget)
        XCTAssertEqual(request.parameters?["site_name"] as? String, campaign.siteName)
        XCTAssertEqual(request.parameters?["text_snippet"] as? String, campaign.textSnippet)
        XCTAssertEqual(request.parameters?["target_url"] as? String, campaign.targetUrl)
        XCTAssertEqual(request.parameters?["url_params"] as? String, campaign.urlParams)

        let mainImageDict = try XCTUnwrap(request.parameters?["main_image"] as? [String: Any])
        XCTAssertEqual(mainImageDict["url"] as? String, mainImage.url)
        XCTAssertEqual(mainImageDict["mime_type"] as? String, mainImage.mimeType)

        let targetingDict = try XCTUnwrap(request.parameters?["targeting"] as? [String: Any])
        XCTAssertEqual(targetingDict["locations"] as? [Int64], targeting.locations)
        XCTAssertEqual(targetingDict["languages"] as? [String], targeting.languages)
        XCTAssertEqual(targetingDict["devices"] as? [String], targeting.devices)
        XCTAssertEqual(targetingDict["page_topics"] as? [String], targeting.pageTopics)

        XCTAssertEqual(request.parameters?["target_urn"] as? String, campaign.targetUrn)
        XCTAssertEqual(request.parameters?["type"] as? String, campaign.type)
    }

    func test_createCampaign_properly_relays_networking_errors() async {
        // Given
        let remote = BlazeRemote(network: network)

        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1.1/campaigns"
        network.simulateError(requestUrlSuffix: suffix, error: expectedError)

        do {
            // When
            _ = try await remote.createCampaign(.fake(), siteID: sampleSiteID)

            // Then
            XCTFail("Request should fail")
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, expectedError)
        }
    }

    // MARK: - Load campaigns tests

    /// Verifies that loadCampaign properly parses the response.
    ///
    func test_loadCampaigns_returns_parsed_campaigns() async throws {
        // Given
        let remote = BlazeRemote(network: network)

        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1/search/campaigns/site/\(sampleSiteID)"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "blaze-campaigns-success")

        // When
        let results = try await remote.loadCampaigns(for: sampleSiteID, pageNumber: 1)

        // Then
        XCTAssertEqual(results.count, 1)
        let item = try XCTUnwrap(results.first)
        XCTAssertEqual(item.siteID, sampleSiteID)
        XCTAssertEqual(item.campaignID, 34518)
        XCTAssertEqual(item.name, "Fried-egg Bacon Bagel")
        XCTAssertEqual(item.uiStatus, "rejected")
        XCTAssertEqual(item.contentClickURL, "https://example.com/product/fried-egg-bacon-bagel/")
        XCTAssertEqual(item.contentImageURL, "https://exampl.com/image?w=600&zoom=2")
        XCTAssertEqual(item.totalBudget, 35)
        XCTAssertEqual(item.totalClicks, 0)
        XCTAssertEqual(item.totalImpressions, 0)
    }

    /// Verifies that loadCampaigns sends the correct parameters.
    ///
    func test_loadCampaigns_sends_correct_parameters() async throws {
        // Given
        let remote = BlazeRemote(network: network)
        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1/search/campaigns/site/\(sampleSiteID)"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "blaze-campaigns-success")

        // When
        _ = try await remote.loadCampaigns(for: sampleSiteID, pageNumber: 1)

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.first as? DotcomRequest)
        XCTAssertEqual(request.parameters?["page"] as? Int, 1)
        XCTAssertEqual(request.parameters?["order_by"] as? String, "post_date")
        XCTAssertEqual(request.parameters?["order"] as? String, "desc")
    }

    /// Verifies that loadCampaigns properly relays Networking Layer errors.
    ///
    func test_loadCampaigns_properly_relays_networking_errors() async {
        // Given
        let remote = BlazeRemote(network: network)

        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1/search/campaigns/site/\(sampleSiteID)"
        network.simulateError(requestUrlSuffix: suffix, error: expectedError)

        do {
            // When
            _ = try await remote.loadCampaigns(for: sampleSiteID, pageNumber: 1)

            // Then
            XCTFail("Request should fail")
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, expectedError)
        }
    }

    // MARK: - Fetch target languages

    func test_fetchTargetLanguages_returns_parsed_campaigns() async throws {
        // Given
        let remote = BlazeRemote(network: network)

        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1.1/targeting/languages"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "blaze-target-languages")

        // When
        let results = try await remote.fetchTargetLanguages(for: sampleSiteID, locale: "vi")

        // Then
        XCTAssertEqual(results, [
            .init(id: "en", name: "English", locale: "vi"),
            .init(id: "es", name: "Spanish", locale: "vi")
        ])
    }

    func test_fetchTargetLanguages_sends_correct_parameters() async throws {
        // Given
        let remote = BlazeRemote(network: network)
        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1.1/targeting/languages"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "blaze-target-languages")

        // When
        _ = try await remote.fetchTargetLanguages(for: sampleSiteID, locale: "en")

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.first as? DotcomRequest)
        XCTAssertEqual(request.parameters?["locale"] as? String, "en")
    }

    func test_fetchTargetLanguages_properly_relays_networking_errors() async {
        // Given
        let remote = BlazeRemote(network: network)

        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1.1/targeting/languages"
        network.simulateError(requestUrlSuffix: suffix, error: expectedError)

        do {
            // When
            _ = try await remote.fetchTargetLanguages(for: sampleSiteID, locale: "en")

            // Then
            XCTFail("Request should fail")
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, expectedError)
        }
    }

    // MARK: - Fetch target devices

    func test_fetchTargetDevices_returns_parsed_campaigns() async throws {
        // Given
        let remote = BlazeRemote(network: network)

        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1.1/targeting/devices"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "blaze-target-devices")

        // When
        let results = try await remote.fetchTargetDevices(for: sampleSiteID, locale: "vi")

        // Then
        XCTAssertEqual(results, [
            .init(id: "mobile", name: "Mobile", locale: "vi"),
            .init(id: "desktop", name: "Desktop", locale: "vi")
        ])
    }

    func test_fetchTargetDevices_sends_correct_parameters() async throws {
        // Given
        let remote = BlazeRemote(network: network)
        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1.1/targeting/devices"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "blaze-target-devices")

        // When
        _ = try await remote.fetchTargetDevices(for: sampleSiteID, locale: "en")

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.first as? DotcomRequest)
        XCTAssertEqual(request.parameters?["locale"] as? String, "en")
    }

    func test_fetchTargetDevices_properly_relays_networking_errors() async {
        // Given
        let remote = BlazeRemote(network: network)

        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1.1/targeting/devices"
        network.simulateError(requestUrlSuffix: suffix, error: expectedError)

        do {
            // When
            _ = try await remote.fetchTargetDevices(for: sampleSiteID, locale: "en")

            // Then
            XCTFail("Request should fail")
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, expectedError)
        }
    }

    // MARK: - Fetch target topics

    func test_fetchTargetTopics_returns_parsed_campaigns() async throws {
        // Given
        let remote = BlazeRemote(network: network)

        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1.1/targeting/page-topics"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "blaze-target-topics")

        // When
        let results = try await remote.fetchTargetTopics(for: sampleSiteID, locale: "vi")

        // Then
        XCTAssertEqual(results, [
            .init(id: "IAB1", description: "Arts & Entertainment", locale: "vi"),
            .init(id: "IAB2", description: "Automotive", locale: "vi"),
            .init(id: "IAB3", description: "Business", locale: "vi")
        ])
    }

    func test_fetchTargetTopics_sends_correct_parameters() async throws {
        // Given
        let remote = BlazeRemote(network: network)
        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1.1/targeting/page-topics"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "blaze-target-topics")

        // When
        _ = try await remote.fetchTargetTopics(for: sampleSiteID, locale: "vi")

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.first as? DotcomRequest)
        XCTAssertEqual(request.parameters?["locale"] as? String, "vi")
    }

    func test_fetchTargetTopics_properly_relays_networking_errors() async {
        // Given
        let remote = BlazeRemote(network: network)

        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1.1/targeting/page-topics"
        network.simulateError(requestUrlSuffix: suffix, error: expectedError)

        do {
            // When
            _ = try await remote.fetchTargetTopics(for: sampleSiteID, locale: "en")

            // Then
            XCTFail("Request should fail")
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, expectedError)
        }
    }

    // MARK: - Fetch target locations

    func test_fetchTargetLocations_returns_parsed_campaigns() async throws {
        // Given
        let remote = BlazeRemote(network: network)
        let query = "test"
        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1.1/targeting/locations"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "blaze-target-locations")

        // When
        let results = try await remote.fetchTargetLocations(for: sampleSiteID, query: query, locale: "en")

        // Then
        XCTAssertEqual(results.count, 3)
        let firstItem = try XCTUnwrap(results.first)
        XCTAssertEqual(firstItem.id, 1439)
        XCTAssertEqual(firstItem.name, "Madrid")
        XCTAssertEqual(firstItem.type, "state")
        XCTAssertNil(firstItem.code)
        XCTAssertNil(firstItem.isoCode)
        XCTAssertEqual(firstItem.parentLocation?.id, 69)
        XCTAssertEqual(firstItem.parentLocation?.parentLocation?.id, 228)
        XCTAssertEqual(firstItem.parentLocation?.parentLocation?.parentLocation?.id, 5)
        XCTAssertNil(firstItem.parentLocation?.parentLocation?.parentLocation?.parentLocation)
    }

    func test_fetchTargetLocations_sends_correct_parameters() async throws {
        // Given
        let remote = BlazeRemote(network: network)
        let query = "test"
        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1.1/targeting/locations"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "blaze-target-locations")

        // When
        _ = try await remote.fetchTargetLocations(for: sampleSiteID, query: query, locale: "en")

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.first as? DotcomRequest)
        XCTAssertEqual(request.parameters?["locale"] as? String, "en")
        XCTAssertEqual(request.parameters?["query"] as? String, query)
    }

    func test_fetchTargetLocations_properly_relays_networking_errors() async {
        // Given
        let remote = BlazeRemote(network: network)
        let query = "test"
        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1.1/targeting/locations"
        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        network.simulateError(requestUrlSuffix: suffix, error: expectedError)

        do {
            // When
            _ = try await remote.fetchTargetLocations(for: sampleSiteID, query: query, locale: "en")

            // Then
            XCTFail("Request should fail")
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, expectedError)
        }
    }

    // MARK: - Fetch forecasted impressions

    func test_fetchForecastedImpressions_returns_parsed_impressions() async throws {
        // Given
        let remote = BlazeRemote(network: network)
        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1.1/forecast"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "blaze-impressions")

        // When
        let result = try await remote.fetchForecastedImpressions(
            for: sampleSiteID,
            with: BlazeForecastedImpressionsInput.fake())

        // Then
        XCTAssertEqual(result, .init(totalImpressionsMin: 17900, totalImpressionsMax: 24200))
    }

    func test_fetchForecastedImpressions_properly_relays_networking_errors() async {
        // Given
        let remote = BlazeRemote(network: network)
        let suffix = "sites/\(sampleSiteID)/wordads/dsp/api/v1.1/forecast"
        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        network.simulateError(requestUrlSuffix: suffix, error: expectedError)

        do {
            // When
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"


            _ = try await remote.fetchForecastedImpressions(
                for: sampleSiteID,
                with: BlazeForecastedImpressionsInput(startDate: dateFormatter.date(from: "2023-12-5")!,
                                                      endDate: dateFormatter.date(from: "2023-12-11")!,
                                                      totalBudget: 35
                                                     )
            )

            // Then
            XCTFail("Request should fail")
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, expectedError)
        }
    }
}
