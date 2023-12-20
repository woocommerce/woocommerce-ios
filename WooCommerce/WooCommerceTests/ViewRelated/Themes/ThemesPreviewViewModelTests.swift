import XCTest
@testable import WooCommerce
@testable import Yosemite
import Combine

@MainActor
final class ThemesPreviewViewModelTests: XCTestCase {
    private var stores: MockStoresManager!
    private var subscriptions = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
    }

    override func tearDown() {
        stores = nil
        super.tearDown()
    }

    func test_initial_state_is_pagesLoading() {
        // Given
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .storeCreationProfiler,
                                               theme: .init(id: "123",
                                                            description: "Woo Theme",
                                                            name: "Woo",
                                                            demoURI: "https://tsubakidemo.wpcomstaging.com/"))

        // Then
        XCTAssertEqual(viewModel.state, .pagesLoading)
        XCTAssertEqual(viewModel.pages.count, 1) // The default "Home" page.
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

        let expectedPages = [
            WordPressPage(id: 1, title: "Page1", link: "https://tsubakidemo.wpcomstaging.com/page1"),
            WordPressPage(id: 2, title: "Page2", link: "https://tsubakidemo.wpcomstaging.com/page2"),
            WordPressPage(id: 3, title: "Page3", link: "https://tsubakidemo.wpcomstaging.com/page3")
        ]

        // When
        stores.whenReceivingAction(ofType: WordPressSiteAction.self) { action in
            switch action {
            case let .fetchPageList(_, completion):
                completion(.success(expectedPages))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
        await viewModel.fetchPages()

        // Then
        XCTAssertEqual(viewModel.pages.count, 4) // 3 pages + 1 default "Home" page.
        XCTAssertEqual(viewModel.state, .pagesContent)
    }

    func test_setSelectedPage() {
        // Given
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .storeCreationProfiler,
                                               theme: .init(id: "123",
                                                            description: "Woo Theme",
                                                            name: "Woo",
                                                            demoURI: "testURL"))
        let page = WordPressPage(id: 1, title: "Page1", link: "testURL")

        // When
        viewModel.setSelectedPage(page: page)

        // Then
        XCTAssertEqual(viewModel.selectedPage, page)
    }

    // MARK: installingTheme

    func test_installingTheme_is_initially_false() {
        // Given
        let viewModel = ThemesPreviewViewModel(siteID: 123,
                                               mode: .storeCreationProfiler,
                                               theme: .init(id: "123",
                                                            description: "Woo Theme",
                                                            name: "Woo",
                                                            demoURI: "https://tsubakidemo.wpcomstaging.com/"))

        // Then
        XCTAssertFalse(viewModel.installingTheme)
    }

    func test_installingTheme_is_updated_properly__when_installing_theme_is_successful() async throws {
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
            .dropFirst() // Initial value
            .collect(2)  // Collect toggle
            .first()
            .sink { states in
                loadingStates = states
            }
            .store(in: &self.subscriptions)

        // When
        try await viewModel.installTheme()

        // Then
        assertEqual(loadingStates, [true, false])
    }

    func test_installingTheme_is_updated_properly_when_installing_theme_fails() async {
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
            .dropFirst() // Initial value
            .collect(2)  // Collect toggle
            .first()
            .sink { states in
                loadingStates = states
            }
            .store(in: &self.subscriptions)

        // When
        do {
            try await viewModel.installTheme()
            XCTFail("Installing theme should fail")
        } catch {
            // Then
            assertEqual(loadingStates, [true, false])
        }
    }

    // MARK: notice

    func test_notice_is_initially_false() {
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
            try await viewModel.installTheme()
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
        try await viewModel.installTheme()

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
        try await viewModel.installTheme()

        // Then
        XCTAssertFalse(themeInstaller.installThemeCalled)
    }
}

private extension ThemesPreviewViewModelTests {
    final class MockError: Error {
        var localizedDescription: String {
            "description"
        }
    }
}
