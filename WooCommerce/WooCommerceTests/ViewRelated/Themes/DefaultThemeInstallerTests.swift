import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class DefaultThemeInstallerTests: XCTestCase {

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
        super.tearDown()
    }

    func test_it_stores_theme_correctly() throws {
        // Given
        let siteID: Int64 = 123
        let themeID = "amulet"
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = DefaultThemeInstaller(stores: stores,
                                        userDefaults: userDefaults)

        // When
        sut.scheduleThemeInstall(themeID: themeID, siteID: siteID)

        // Then
        let themes = try XCTUnwrap(userDefaults[.themesPendingInstall] as? [String: String])
        XCTAssertEqual(themes["\(siteID)"], themeID)
    }

    func test_it_installs_theme_if_stored_theme_available() async throws {
        // Given
        let siteID: Int64 = 123
        let themeID = "amulet"
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = DefaultThemeInstaller(stores: stores,
                                        userDefaults: userDefaults)
        var installedThemeID: String?
        var themeInstalledForSiteID: Int64?

        var activatedThemeID: String?
        var themeActivatedForSiteID: Int64?

        sut.scheduleThemeInstall(themeID: themeID, siteID: siteID)

        // When

        stores.whenReceivingAction(ofType: WordPressThemeAction.self) { action in
            if case let .installTheme(themeID, siteID, onCompletion) = action {
                onCompletion(.success(.fake().copy(id: themeID)))
                installedThemeID = themeID
                themeInstalledForSiteID = siteID
            }
            if case let .activateTheme(themeID, siteID, onCompletion) = action {
                onCompletion(.success(.fake().copy(id: themeID)))
                activatedThemeID = themeID
                themeActivatedForSiteID = siteID
            }
        }

        try await sut.installPendingThemeIfNeeded(siteID: siteID)

        // Then
        XCTAssertEqual(installedThemeID, themeID)
        XCTAssertEqual(themeInstalledForSiteID, siteID)

        XCTAssertEqual(activatedThemeID, themeID)
        XCTAssertEqual(themeActivatedForSiteID, siteID)
    }

    func test_it_clears_stored_theme_if_installation_successful() async throws {
        // Given
        let siteID: Int64 = 123
        let themeID = "amulet"
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = DefaultThemeInstaller(stores: stores,
                                        userDefaults: userDefaults)

        sut.scheduleThemeInstall(themeID: themeID, siteID: siteID)

        // When

        stores.whenReceivingAction(ofType: WordPressThemeAction.self) { action in
            if case let .installTheme(themeID, _, onCompletion) = action {
                onCompletion(.success(.fake().copy(id: themeID)))
            }
            if case let .activateTheme(themeID, _, onCompletion) = action {
                onCompletion(.success(.fake().copy(id: themeID)))
            }
        }

        try await sut.installPendingThemeIfNeeded(siteID: siteID)

        // Then
        let themes = try XCTUnwrap(userDefaults[.themesPendingInstall] as? [String: String])
        XCTAssertNil(themes["\(siteID)"])
    }

    func test_it_does_not_attempt_theme_installation_if_stored_theme_not_available() async throws {
        // Given
        let siteID: Int64 = 123
        let themeID = "amulet"
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let stores = MockStoresManager(sessionManager: .makeForTesting())

        let sut = DefaultThemeInstaller(stores: stores,
                                        userDefaults: userDefaults)
        sut.scheduleThemeInstall(themeID: themeID, siteID: siteID)

        var installedThemeID: String?
        var activatedThemeID: String?

        // When
        stores.whenReceivingAction(ofType: WordPressThemeAction.self) { action in
            if case let .installTheme(themeID, _, onCompletion) = action {
                onCompletion(.success(.fake().copy(id: themeID)))
                installedThemeID = themeID
            }
            if case let .activateTheme(themeID, _, onCompletion) = action {
                onCompletion(.success(.fake().copy(id: themeID)))
                activatedThemeID = themeID
            }
        }

        try await sut.installPendingThemeIfNeeded(siteID: 132) // Different site ID

        // Then
        XCTAssertNil(installedThemeID)
        XCTAssertNil(activatedThemeID)
    }

    func test_install_tracks_success() async throws {
        // Given
        let themeID = "tsubaki"
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = DefaultThemeInstaller(stores: stores, analytics: analytics)

        // When
        stores.whenReceivingAction(ofType: WordPressThemeAction.self) { action in
            switch action {
            case let .installTheme(themeID, _, onCompletion):
                onCompletion(.success(.fake().copy(id: themeID)))
            case let .activateTheme(themeID, _, onCompletion):
                onCompletion(.success(.fake().copy(id: themeID)))
            default:
                break
            }
        }
        try await sut.install(themeID: themeID, siteID: 99)

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "theme_installation_completed"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["theme"] as? String, themeID)
    }

    func test_install_tracks_installation_failure() async throws {
        // Given
        let themeID = "tsubaki"
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = DefaultThemeInstaller(stores: stores, analytics: analytics)
        let error = NSError(domain: "test", code: 501)

        // When
        stores.whenReceivingAction(ofType: WordPressThemeAction.self) { action in
            switch action {
            case let .installTheme(_, _, onCompletion):
                onCompletion(.failure(error))
            default:
                break
            }
        }
        try? await sut.install(themeID: themeID, siteID: 99)

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "theme_installation_failed"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["error_code"] as? String, "501")
    }

    func test_install_tracks_activation_failure() async throws {
        // Given
        let themeID = "tsubaki"
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = DefaultThemeInstaller(stores: stores, analytics: analytics)

        // When
        stores.whenReceivingAction(ofType: WordPressThemeAction.self) { action in
            switch action {
            case let .installTheme(themeID, _, onCompletion):
                onCompletion(.success(.fake().copy(id: themeID)))
            case let .activateTheme(_, _, onCompletion):
                let error = NSError(domain: "test", code: 500)
                onCompletion(.failure(error))
            default:
                break
            }
        }
        try? await sut.install(themeID: themeID, siteID: 99)

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "theme_installation_failed"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["error_code"] as? String, "500")
    }

    func test_installPendingThemeIfNeeded_tracks_success() async throws {
        // Given
        let siteID: Int64 = 123
        let themeID = "amulet"
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = DefaultThemeInstaller(stores: stores,
                                        userDefaults: userDefaults,
                                        analytics: analytics)

        sut.scheduleThemeInstall(themeID: themeID, siteID: siteID)

        // When
        stores.whenReceivingAction(ofType: WordPressThemeAction.self) { action in
            switch action {
            case let .installTheme(themeID, _, onCompletion):
                onCompletion(.success(.fake().copy(id: themeID)))
            case let .activateTheme(themeID, _, onCompletion):
                onCompletion(.success(.fake().copy(id: themeID)))
            default:
                break
            }
        }

        try await sut.installPendingThemeIfNeeded(siteID: siteID)

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "theme_installation_completed"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["theme"] as? String, themeID)
    }

    func test_installPendingThemeIfNeeded_tracks_failure() async throws {
        // Given
        let siteID: Int64 = 123
        let themeID = "amulet"
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = DefaultThemeInstaller(stores: stores,
                                        userDefaults: userDefaults,
                                        analytics: analytics)

        sut.scheduleThemeInstall(themeID: themeID, siteID: siteID)

        // When
        stores.whenReceivingAction(ofType: WordPressThemeAction.self) { action in
            switch action {
            case let .installTheme(themeID, _, onCompletion):
                onCompletion(.success(.fake().copy(id: themeID)))
            case let .activateTheme(_, _, onCompletion):
                let error = NSError(domain: "test", code: 500)
                onCompletion(.failure(error))
            default:
                break
            }
        }

        try? await sut.installPendingThemeIfNeeded(siteID: siteID)

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "theme_installation_failed"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["error_code"] as? String, "500")
    }
}
