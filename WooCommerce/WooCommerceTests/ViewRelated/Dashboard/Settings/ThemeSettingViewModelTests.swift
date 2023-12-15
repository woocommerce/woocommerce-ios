import XCTest
@testable import WooCommerce
@testable import Yosemite

@MainActor
final class ThemeSettingViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 123

    func test_updateCurrentThemeName_updates_loadingCurrentTheme_properly() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ThemeSettingViewModel(siteID: 123, stores: stores)
        XCTAssertFalse(viewModel.loadingCurrentTheme)

        // When
        stores.whenReceivingAction(ofType: WordPressThemeAction.self) { action in
            switch action {
            case let .loadCurrentTheme(_, onCompletion):
                XCTAssertTrue(viewModel.loadingCurrentTheme)
                onCompletion(.success(.fake()))
            default:
                break
            }
        }
        await viewModel.updateCurrentThemeName()

        // Then
        XCTAssertFalse(viewModel.loadingCurrentTheme)
    }

    func test_updateCurrentThemeName_updates_correct_name_from_loaded_theme() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ThemeSettingViewModel(siteID: 123, stores: stores)
        let expectedName = "Tsubaki"

        // When
        stores.whenReceivingAction(ofType: WordPressThemeAction.self) { action in
            switch action {
            case let .loadCurrentTheme(_, onCompletion):
                onCompletion(.success(.fake().copy(name: expectedName)))
            default:
                break
            }
        }
        await viewModel.updateCurrentThemeName()

        // Then
        XCTAssertEqual(viewModel.currentThemeName, expectedName)
    }

    func test_updateCurrentTheme_updates_currentThemeName() {
        // Given
        let viewModel = ThemeSettingViewModel(siteID: 123)
        XCTAssertEqual(viewModel.currentThemeName, "")

        // When
        viewModel.updateCurrentTheme(.fake().copy(name: "tsubaki"))

        // Then
        XCTAssertEqual(viewModel.currentThemeName, "tsubaki")
    }

    func test_it_triggers_pending_theme_installation_upon_initialization() async {
        // Given
        let themeInstaller = MockThemeInstaller()
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        _ = ThemeSettingViewModel(siteID: 123,
                                  stores: stores,
                                  themeInstaller: themeInstaller)
        // Then
        waitUntil {
            themeInstaller.installPendingThemeCalled == true
        }
    }
}
