import XCTest
@testable import WooCommerce
@testable import Yosemite

@MainActor
final class ThemesCarouselViewModelTests: XCTestCase {

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

    func test_state_is_loading_initially() {
        // Given
        let viewModel = ThemesCarouselViewModel(siteID: 123,
                                                mode: .themeSettings)

        // When
        let state = viewModel.state

        // Then
        XCTAssertEqual(state, .loading)
    }

    func test_state_is_content_after_loading_themes_for_profiler_mode() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ThemesCarouselViewModel(siteID: 123,
                                                mode: .storeCreationProfiler,
                                                stores: stores)
        let expectedThemes: [WordPressTheme] = [.fake().copy(name: "Tsubaki")]

        // When
        stores.whenReceivingAction(ofType: WordPressThemeAction.self) { action in
            switch action {
            case .loadSuggestedThemes(let onCompletion):
                onCompletion(.success(expectedThemes))
            default:
                break
            }
        }
        await viewModel.fetchThemes(isReload: false)

        // Then
        XCTAssertEqual(viewModel.state, .content(themes: expectedThemes))
    }

    func test_state_is_error_after_loading_themes_failed() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ThemesCarouselViewModel(siteID: 123,
                                                mode: .themeSettings,
                                                stores: stores)

        // When
        stores.whenReceivingAction(ofType: WordPressThemeAction.self) { action in
            switch action {
            case .loadSuggestedThemes(let onCompletion):
                onCompletion(.failure(NSError(domain: "Test", code: 503)))
            default:
                break
            }
        }
        await viewModel.fetchThemes(isReload: false)

        // Then
        XCTAssertEqual(viewModel.state, .error)
    }

    func test_fetchThemes_filters_out_matching_theme_id() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ThemesCarouselViewModel(siteID: 123,
                                                mode: .themeSettings,
                                                stores: stores)
        let theme1: WordPressTheme = .fake().copy(id: "tsubaki")
        let theme2: WordPressTheme = .fake().copy(id: "tazza")
        let expectedThemes: [WordPressTheme] = [theme1, theme2]

        // When
        stores.whenReceivingAction(ofType: WordPressThemeAction.self) { action in
            switch action {
            case .loadSuggestedThemes(let onCompletion):
                onCompletion(.success(expectedThemes))
            case let .loadCurrentTheme(_, onCompletion):
                onCompletion(.success(theme1))
            default:
                break
            }
        }
        await viewModel.fetchThemes(isReload: false)
        viewModel.updateCurrentTheme(id: theme1.id)

        // Then
        waitUntil {
            viewModel.state == .content(themes: [theme2])
        }
    }

    func test_state_is_error_if_filtered_theme_list_is_empty() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ThemesCarouselViewModel(siteID: 123,
                                                mode: .themeSettings,
                                                stores: stores)
        let theme1: WordPressTheme = .fake().copy(id: "tsubaki")
        let expectedThemes: [WordPressTheme] = [theme1]

        // When
        stores.whenReceivingAction(ofType: WordPressThemeAction.self) { action in
            switch action {
            case .loadSuggestedThemes(let onCompletion):
                onCompletion(.success(expectedThemes))
            case let .loadCurrentTheme(_, onCompletion):
                onCompletion(.success(theme1))
            default:
                break
            }
        }
        await viewModel.fetchThemes(isReload: false)
        viewModel.updateCurrentTheme(id: theme1.id)

        // Then
        waitUntil {
            viewModel.state == .error
        }
    }

    func test_trackViewAppear_tracks_theme_picker_screen_displayed_correctly_for_themeSettings_mode() throws {
        // Given
        let viewModel = ThemesCarouselViewModel(siteID: 123,
                                                mode: .themeSettings,
                                                analytics: analytics)

        // When
        viewModel.trackViewAppear()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "theme_picker_screen_displayed"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["source"] as? String, "settings")
    }

    func test_trackViewAppear_tracks_theme_picker_screen_displayed_correctly_for_profiler_mode() throws {
        // Given
        let viewModel = ThemesCarouselViewModel(siteID: 123,
                                                mode: .storeCreationProfiler,
                                                analytics: analytics)

        // When
        viewModel.trackViewAppear()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "theme_picker_screen_displayed"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["source"] as? String, "store_creation")
    }

    func test_trackThemeSelected_tracks_theme_picker_theme_selected() throws {
        // Given
        let viewModel = ThemesCarouselViewModel(siteID: 123,
                                                mode: .themeSettings,
                                                analytics: analytics)

        // When
        viewModel.trackThemeSelected(.fake().copy(id: "tsubaki"))

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "theme_picker_theme_selected"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["theme"] as? String, "tsubaki")
    }
}
