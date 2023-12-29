import XCTest
@testable import Networking

final class WordPressThemeRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private var network: MockNetwork!

    private let sampleSiteID: Int64 = 123

    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    // MARK: - loadSuggestedThemes tests

    func test_loadSuggestedThemes_returns_parsed_themes() async throws {
        // Given
        let remote = WordPressThemeRemote(network: network)

        let suffix = "themes?filter=subject:store&number=100"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "theme-list-success")

        // When
        let results = try await remote.loadSuggestedThemes()

        // Then
        XCTAssertEqual(results.count, 1)
        let item = try XCTUnwrap(results.first)
        XCTAssertEqual(item.id, "tsubaki")
        XCTAssertEqual(item.name, "Tsubaki")
        // swiftlint:disable:next line_length
        XCTAssertEqual(item.description, "Tsubaki puts the spotlight on your products and your customers.  This theme leverages WooCommerce to provide you with intuitive product navigation and the patterns you need to master digital merchandising.")
        XCTAssertEqual(item.demoURI, "https://tsubakidemo.wpcomstaging.com/")
    }

    func test_loadSuggestedThemes_properly_relays_networking_errors() async {
        // Given
        let remote = WordPressThemeRemote(network: network)

        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        let suffix = "themes?filter=subject:store&number=100"
        network.simulateError(requestUrlSuffix: suffix, error: expectedError)

        do {
            // When
            _ = try await remote.loadSuggestedThemes()

            // Then
            XCTFail("Request should fail")
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, expectedError)
        }
    }

    // MARK: - loadCurrentTheme tests

    func test_loadCurrentTheme_returns_parsed_theme() async throws {
        // Given
        let remote = WordPressThemeRemote(network: network)

        let suffix = "sites/\(sampleSiteID)/themes/mine"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "theme-mine-success")

        // When
        let theme = try await remote.loadCurrentTheme(siteID: sampleSiteID)

        // Then
        XCTAssertEqual(theme.id, "maywood")
        XCTAssertEqual(theme.name, "Maywood")
        XCTAssertEqual(theme.description, "Maywood is a refined theme designed for restaurants and food-related businesses seeking a modern look.")
        XCTAssertEqual(theme.demoURI, "")
    }

    func test_loadCurrentTheme_properly_relays_networking_errors() async {
        // Given
        let remote = WordPressThemeRemote(network: network)

        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        let suffix = "sites/\(sampleSiteID)/themes/mine"
        network.simulateError(requestUrlSuffix: suffix, error: expectedError)

        do {
            // When
            _ = try await remote.loadCurrentTheme(siteID: sampleSiteID)

            // Then
            XCTFail("Request should fail")
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, expectedError)
        }
    }

    // MARK: - installTheme tests

    func test_installTheme_returns_installed_theme() async throws {
        // Given
        let remote = WordPressThemeRemote(network: network)

        let sampleTheme = WordPressTheme.fake().copy(id: "maywood")
        let suffix = "sites/\(sampleSiteID)/themes/\(sampleTheme.id)/install/"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "theme-install-success")

        // When
        let theme = try await remote.installTheme(themeID: sampleTheme.id, siteID: sampleSiteID)

        // Then
        XCTAssertEqual(theme.id, sampleTheme.id)
        XCTAssertEqual(theme.name, "Maywood")
        XCTAssertEqual(theme.description, "Maywood is a refined theme designed for restaurants and food-related businesses seeking a modern look.")
    }

    func test_installTheme_properly_relays_themeAlreadyInstalled_error() async {
        // Given
        let remote = WordPressThemeRemote(network: network)

        let expectedError = InstallThemeError.themeAlreadyInstalled
        let sampleTheme = WordPressTheme.fake().copy(id: "maywood")
        let suffix = "sites/\(sampleSiteID)/themes/\(sampleTheme.id)/install/"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "theme-install-already-installed")

        do {
            // When
            _ = try await remote.installTheme(themeID: sampleTheme.id, siteID: sampleSiteID)

            // Then
            XCTFail("Request should fail")
        } catch {
            // Then
            XCTAssertEqual(error as? InstallThemeError, expectedError)
        }
    }

    func test_installTheme_properly_relays_networking_errors() async {
        // Given
        let remote = WordPressThemeRemote(network: network)

        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        let sampleTheme = WordPressTheme.fake().copy(id: "maywood")
        let suffix = "sites/\(sampleSiteID)/themes/\(sampleTheme.id)/install/"
        network.simulateError(requestUrlSuffix: suffix, error: expectedError)

        do {
            // When
            _ = try await remote.installTheme(themeID: sampleTheme.id, siteID: sampleSiteID)

            // Then
            XCTFail("Request should fail")
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, expectedError)
        }
    }

    // MARK: - activateTheme tests

    func test_activateTheme_returns_activated_theme() async throws {
        // Given
        let remote = WordPressThemeRemote(network: network)

        let sampleTheme = WordPressTheme.fake().copy(id: "maywood")
        let suffix = "sites/\(sampleSiteID)/themes/mine"
        network.simulateResponse(requestUrlSuffix: suffix, filename: "theme-activate-success")

        // When
        let theme = try await remote.activateTheme(themeID: sampleTheme.id, siteID: sampleSiteID)

        // Then
        XCTAssertEqual(theme.id, sampleTheme.id)
        XCTAssertEqual(theme.name, "Maywood")
        XCTAssertEqual(theme.description, "Maywood is a refined theme designed for restaurants and food-related businesses seeking a modern look.")
    }

    func test_activateTheme_properly_relays_networking_errors() async {
        // Given
        let remote = WordPressThemeRemote(network: network)

        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        let sampleTheme = WordPressTheme.fake().copy(id: "maywood")
        let suffix = "sites/\(sampleSiteID)/themes/mine"
        network.simulateError(requestUrlSuffix: suffix, error: expectedError)

        do {
            // When
            _ = try await remote.activateTheme(themeID: sampleTheme.id, siteID: sampleSiteID)

            // Then
            XCTFail("Request should fail")
        } catch {
            // Then
            XCTAssertEqual(error as? NetworkError, expectedError)
        }
    }
}
