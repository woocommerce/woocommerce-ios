import XCTest
@testable import WooCommerce
@testable import Yosemite

@MainActor
final class ThemesCarouselViewModelTests: XCTestCase {

    func test_state_is_loading_initially() {
        // Given
        let viewModel = ThemesCarouselViewModel()

        // When
        let state = viewModel.state

        // Then
        XCTAssertEqual(state, .loading)
    }

    func test_state_is_content_after_loading_themes() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ThemesCarouselViewModel(stores: stores)
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
        await viewModel.fetchThemes()

        // Then
        XCTAssertEqual(viewModel.state, .content(themes: expectedThemes))
    }

    func test_state_is_error_after_loading_themes_failed() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ThemesCarouselViewModel(stores: stores)

        // When
        stores.whenReceivingAction(ofType: WordPressThemeAction.self) { action in
            switch action {
            case .loadSuggestedThemes(let onCompletion):
                onCompletion(.failure(NSError(domain: "Test", code: 503)))
            default:
                break
            }
        }
        await viewModel.fetchThemes()

        // Then
        XCTAssertEqual(viewModel.state, .error)
    }

    func test_fetchThemes_filters_out_matching_theme_id() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = ThemesCarouselViewModel(stores: stores)
        let theme1: WordPressTheme = .fake().copy(id: "tsubaki")
        let theme2: WordPressTheme = .fake().copy(id: "tazza")
        let expectedThemes: [WordPressTheme] = [theme1, theme2]

        // When
        stores.whenReceivingAction(ofType: WordPressThemeAction.self) { action in
            switch action {
            case .loadSuggestedThemes(let onCompletion):
                onCompletion(.success(expectedThemes))
            default:
                break
            }
        }
        await viewModel.fetchThemes(currentThemeID: theme1.id)

        // Then
        XCTAssertEqual(viewModel.state, .content(themes: [theme2]))
    }
}
