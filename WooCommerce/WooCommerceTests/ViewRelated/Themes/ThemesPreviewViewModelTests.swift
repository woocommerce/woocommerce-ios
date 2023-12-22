import XCTest
@testable import WooCommerce
@testable import Yosemite
import Combine

@MainActor
final class ThemesPreviewViewModelTests: XCTestCase {
    private var stores: MockStoresManager!
    private var subscriptions = Set<AnyCancellable>()
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()

        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
    }

    override func tearDown() {
        stores = nil
        analytics = nil
        analyticsProvider = nil
        super.tearDown()
    }

    func test_initial_state_is_pagesLoading() {
        // Given
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .storeCreationProfiler,
                                               theme: .init(id: "123",
                                                            description: "Woo Theme",
                                                            name: "Woo",
                                                            demoURI: "https://tsubakidemo.wpcomstaging.com/"),
                                               stores: stores)

        // Then
        XCTAssertEqual(viewModel.state, .pagesLoading)
    }

    func test_initial_pages_content() {
        // Given
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .storeCreationProfiler,
                                               theme: .init(id: "123",
                                                            description: "Woo Theme",
                                                            name: "Woo",
                                                            demoURI: "https://tsubakidemo.wpcomstaging.com/"),
                                               stores: stores)
        // Then
        XCTAssertEqual(viewModel.pages.count, 1)
        XCTAssertEqual(viewModel.pages.first?.title, "Home")
    }

    func test_initial_selectedPageURL() {
        // Given
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .storeCreationProfiler,
                                               theme: .init(id: "123",
                                                            description: "Woo Theme",
                                                            name: "Woo",
                                                            demoURI: "https://tsubakidemo.wpcomstaging.com/"),
                                               stores: stores)

        // Then
        XCTAssertEqual(viewModel.selectedPageUrl, URL(string: "https://tsubakidemo.wpcomstaging.com/" + Expectations.demoSuffix))
    }

    func test_fetchPages_sets_the_right_pages_and_state() async {
        // Given
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .storeCreationProfiler,
                                               theme: .init(id: "123",
                                                            description: "Woo Theme",
                                                            name: "Woo",
                                                            demoURI: "https://tsubakidemo.wpcomstaging.com/"),
                                               stores: stores)

        // When
        stores.whenReceivingAction(ofType: WordPressSiteAction.self) { action in
            switch action {
            case let .fetchPageList(_, completion):
                completion(.success(Expectations.expectedPages))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
        await viewModel.fetchPages()

        // Then
        XCTAssertEqual(viewModel.pages.count, 4) // 3 pages + 1 default "Home" page.
        XCTAssertEqual(viewModel.state, .pagesContent)
    }

    func test_fetchPages_success_sets_right_state() async {
        // Given
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .storeCreationProfiler,
                                               theme: .init(id: "123",
                                                            description: "Woo Theme",
                                                            name: "Woo",
                                                            demoURI: "https://tsubakidemo.wpcomstaging.com/"),
                                               stores: stores)

        // When
        stores.whenReceivingAction(ofType: WordPressSiteAction.self) { action in
            switch action {
            case let .fetchPageList(_, completion):
                completion(.success([]))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
        await viewModel.fetchPages()

        // Then
        XCTAssertEqual(viewModel.state, .pagesContent)
    }

    func test_fetchPages_sets_right_pages_content() async {
        // Given
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .storeCreationProfiler,
                                               theme: .init(id: "123",
                                                            description: "Woo Theme",
                                                            name: "Woo",
                                                            demoURI: "https://tsubakidemo.wpcomstaging.com/"),
                                               stores: stores)

        // When
        stores.whenReceivingAction(ofType: WordPressSiteAction.self) { action in
            switch action {
            case let .fetchPageList(_, completion):
                completion(.success(Expectations.expectedPages))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
        await viewModel.fetchPages()

        // Then
        XCTAssertEqual(viewModel.pages.count, 4) // 3 pages + 1 default "Home" page.

        // Check home page still exists
        let homePage = viewModel.pages[0]
        XCTAssertEqual(homePage.title, "Home")
        XCTAssertEqual(homePage.link, "https://tsubakidemo.wpcomstaging.com/")

        // Check remaining pages
        for (index, page) in viewModel.pages.enumerated() {
            if index == 0 { continue }

            let expectedPage = Expectations.expectedPages[index-1]
            XCTAssertEqual(page.id, expectedPage.id)
            XCTAssertEqual(page.title, expectedPage.title)

            // Check that the URL is correct
            XCTAssertEqual(page.link, expectedPage.link)
        }

    }

    func test_fetchPages_failure_sets_right_state() async {
        // Given
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .storeCreationProfiler,
                                               theme: .init(id: "123",
                                                            description: "Woo Theme",
                                                            name: "Woo",
                                                            demoURI: "https://tsubakidemo.wpcomstaging.com/"),
                                               stores: stores)

        // When
        stores.whenReceivingAction(ofType: WordPressSiteAction.self) { action in
            switch action {
            case let .fetchPageList(_, completion):
                completion(.failure(NSError(domain: "Test", code: 503)))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
        await viewModel.fetchPages()

        // Then
        XCTAssertEqual(viewModel.state, .pagesLoadingError)
    }

    func test_setSelectedPage_updates_selectedPage() {
        // Given
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .storeCreationProfiler,
                                               theme: .init(id: "123",
                                                            description: "Woo Theme",
                                                            name: "Woo",
                                                            demoURI: "https://tsubakidemo.wpcomstaging.com/"),
                                               stores: stores)
        let page = WordPressPage(id: 1, title: "Page1", link: "https://tsubakidemo.wpcomstaging.com/page1")

        // When
        viewModel.setSelectedPage(page: page)

        // Then
        XCTAssertEqual(viewModel.selectedPage, page)
    }

    func test_setSelectedPage_updates_selectedPageLink() {
        // Given
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .storeCreationProfiler,
                                               theme: .init(id: "123",
                                                            description: "Woo Theme",
                                                            name: "Woo",
                                                            demoURI: "https://tsubakidemo.wpcomstaging.com/"),
                                               stores: stores)
        let page = WordPressPage(id: 1, title: "Page1", link: "https://tsubakidemo.wpcomstaging.com/page1")

        // When
        viewModel.setSelectedPage(page: page)

        // Then
        XCTAssertEqual(viewModel.selectedPageUrl, URL(string: page.link + Expectations.demoSuffix))
    }

    // MARK: installingTheme

    func test_installingTheme_is_initially_false() {
        // Given
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .storeCreationProfiler,
                                               theme: .init(id: "123",
                                                            description: "Woo Theme",
                                                            name: "Woo",
                                                            demoURI: "https://tsubakidemo.wpcomstaging.com/"),
                                               stores: stores)

        // Then
        XCTAssertFalse(viewModel.installingTheme)
    }

    func test_installingTheme_is_updated_properly_when_installing_theme_is_successful_in_themeSettings_mode() async throws {
        // Given
        let themeInstaller = MockThemeInstaller()
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .themeSettings,
                                               theme: .init(id: "123",
                                                            description: "Woo Theme",
                                                            name: "Woo",
                                                            demoURI: "https://tsubakidemo.wpcomstaging.com/"),
                                               stores: stores,
                                               themeInstaller: themeInstaller)
        var loadingStates = [Bool]()
        viewModel.$installingTheme
            .collect(3)
            .sink { states in
                loadingStates = states
            }
            .store(in: &self.subscriptions)

        // When
        try await viewModel.confirmThemeSelection()

        // Then
        assertEqual([false, true, false], loadingStates)
    }

    func test_installingTheme_does_not_change_when_theme_selection_confirmed_in_storeCreationProfiler_mode() async throws {
        // Given
        let themeInstaller = MockThemeInstaller()
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .storeCreationProfiler,
                                               theme: .init(id: "123",
                                                            description: "Woo Theme",
                                                            name: "Woo",
                                                            demoURI: "https://tsubakidemo.wpcomstaging.com/"),
                                               stores: stores,
                                               themeInstaller: themeInstaller)
        var loadingStates = [Bool]()
        viewModel.$installingTheme
            .collect()
            .sink { states in
                loadingStates = states
            }
            .store(in: &self.subscriptions)

        // When
        try await viewModel.confirmThemeSelection()

        // Then
        assertEqual([], loadingStates)
    }

    func test_installingTheme_is_updated_properly_when_installing_theme_fails_in_themeSettings_mode() async {
        // Given
        let themeInstaller = MockThemeInstaller()
        themeInstaller.installThemeError = MockError()
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .themeSettings,
                                               theme: .init(id: "123",
                                                            description: "Woo Theme",
                                                            name: "Woo",
                                                            demoURI: "https://tsubakidemo.wpcomstaging.com/"),
                                               stores: stores,
                                               themeInstaller: themeInstaller)
        var loadingStates = [Bool]()
        viewModel.$installingTheme
            .collect(3)
            .sink { states in
                loadingStates = states
            }
            .store(in: &self.subscriptions)

        // When
        do {
            try await viewModel.confirmThemeSelection()
            XCTFail("Installing theme should fail")
        } catch {
            // Then
            assertEqual([false, true, false], loadingStates)
        }
    }

    // MARK: notice

    func test_notice_is_initially_nil() {
        // Given
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .storeCreationProfiler,
                                               theme: .init(id: "123",
                                                            description: "Woo Theme",
                                                            name: "Woo",
                                                            demoURI: "https://tsubakidemo.wpcomstaging.com/"),
                                               stores: stores)

        // Then
        XCTAssertNil(viewModel.notice)
    }

    func test_notice_is_not_nil_when_installing_theme_fails() async {
        // Given
        let themeInstaller = MockThemeInstaller()
        themeInstaller.installThemeError = MockError()
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .themeSettings,
                                               theme: .init(id: "123",
                                                            description: "Woo Theme",
                                                            name: "Woo",
                                                            demoURI: "https://tsubakidemo.wpcomstaging.com/"),
                                               stores: stores,
                                               themeInstaller: themeInstaller)

        // When
        do {
            try await viewModel.confirmThemeSelection()
            XCTFail("Installing theme should fail")
        } catch {
            // Then
            XCTAssertNotNil(viewModel.notice)
        }
    }

    // MARK: Theme installation

    func test_it_installs_theme_when_mode_is_themeSettings() async throws {
        // Given
        let themeInstaller = MockThemeInstaller()
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .themeSettings,
                                               theme: .init(id: "123",
                                                            description: "Woo Theme",
                                                            name: "Woo",
                                                            demoURI: "https://tsubakidemo.wpcomstaging.com/"),
                                               stores: stores,
                                               themeInstaller: themeInstaller)

        // When
        try await viewModel.confirmThemeSelection()

        // Then
        XCTAssertTrue(themeInstaller.installThemeCalled)
        XCTAssertEqual(themeInstaller.installThemeCalledForSiteID, 123)
        XCTAssertEqual(themeInstaller.installThemeCalledWithThemeID, "123")
    }

    func test_it_does_not_install_theme_when_mode_is_storeCreationProfiler() async throws {
        // Given
        let themeInstaller = MockThemeInstaller()
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .storeCreationProfiler,
                                               theme: .init(id: "123",
                                                            description: "Woo Theme",
                                                            name: "Woo",
                                                            demoURI: "https://tsubakidemo.wpcomstaging.com/"),
                                               stores: stores,
                                               themeInstaller: themeInstaller)

        // When
        try await viewModel.confirmThemeSelection()

        // Then
        XCTAssertFalse(themeInstaller.installThemeCalled)
    }

    func test_it_tracks_button_tap_when_confirming_theme_selection() async throws {
        // Given
        let themeInstaller = MockThemeInstaller()
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .storeCreationProfiler,
                                               theme: .fake().copy(id: "tsubaki"),
                                               stores: stores,
                                               analytics: analytics,
                                               themeInstaller: themeInstaller)

        // When
        try await viewModel.confirmThemeSelection()

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "theme_preview_start_with_theme_button_tapped"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["theme"] as? String, "tsubaki")
    }

    func test_trackViewAppear_tracks_preview_screen_displayed() throws {
        // Given
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .storeCreationProfiler,
                                               theme: .fake().copy(id: "tsubaki"),
                                               stores: stores,
                                               analytics: analytics)

        // When
        viewModel.trackViewAppear()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents, ["theme_preview_screen_displayed"])
    }

    func test_trackLayoutSwitch_tracks_theme_preview_layout_selected() throws {
        // Given
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .storeCreationProfiler,
                                               theme: .fake().copy(id: "tsubaki"),
                                               analytics: analytics)

        // When
        viewModel.trackLayoutSwitch(layout: .tablet)

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "theme_preview_layout_selected"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["layout"] as? String, "tablet")
    }

    func test_setSelectedPage_tracks_theme_preview_page_selected() throws {
        // Given
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .storeCreationProfiler,
                                               theme: .fake().copy(id: "tsubaki"),
                                               analytics: analytics)

        // When
        viewModel.setSelectedPage(page: .fake().copy(title: "Test", link: "https://example.com"))

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "theme_preview_page_selected"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["page"] as? String, "Test")
        XCTAssertEqual(eventProperties["page_url"] as? String, "https://example.com")
    }
}

private extension ThemesPreviewViewModelTests {
    enum Expectations {
        static let expectedPages = [
            WordPressPage(id: 1, title: "Page1", link: "https://tsubakidemo.wpcomstaging.com/page1"),
            WordPressPage(id: 2, title: "Page2", link: "https://tsubakidemo.wpcomstaging.com/page2"),
            WordPressPage(id: 3, title: "Page3", link: "https://tsubakidemo.wpcomstaging.com/page3")
        ]
        static let demoSuffix = "?demo"
    }
}

private extension ThemesPreviewViewModelTests {
    final class MockError: Error {
        var localizedDescription: String {
            "description"
        }
    }
}
