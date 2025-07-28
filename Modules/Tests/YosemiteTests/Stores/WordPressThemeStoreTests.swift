import XCTest
@testable import Networking
@testable import Yosemite
@testable import Storage

final class WordPressThemeStoreTests: XCTestCase {

    private var dispatcher: Dispatcher!

    private var network: MockNetwork!

    private var remote: MockWordPressThemeRemote!

    private var storageManager: MockStorageManager!

    override func setUp() {
        super.setUp()
        network = MockNetwork()
        dispatcher = Dispatcher()
        remote = MockWordPressThemeRemote()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        network = nil
        dispatcher = nil
        remote = nil
        storageManager = nil
        super.tearDown()
    }

    // MARK: - loadSuggestedThemes tests

    func test_loadSuggestedThemes_returns_themes_on_success() throws {
        // Given
        remote.whenLoadingSuggestedTheme(thenReturn: .success([.fake().copy(id: "tsubaki")]))
        let store = WordPressThemeStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(WordPressThemeAction.loadSuggestedThemes(onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let themes = try result.get()
        XCTAssertEqual(themes.count, 1)
        XCTAssertEqual(themes.first?.id, "tsubaki")
    }

    func test_loadSuggestedThemes_returns_error_on_failure() throws {
        // Given
        remote.whenLoadingSuggestedTheme(thenReturn: .failure(NetworkError.timeout()))
        let store = WordPressThemeStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(WordPressThemeAction.loadSuggestedThemes(onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }

    // MARK: - loadCurrentTheme tests

    func test_loadCurrentTheme_returns_theme_on_success() throws {
        // Given
        remote.whenLoadingCurrentTheme(thenReturn: .success(.fake().copy(name: "Tsubaki")))
        let store = WordPressThemeStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(WordPressThemeAction.loadCurrentTheme(siteID: 123, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let theme = try result.get()
        XCTAssertEqual(theme.name, "Tsubaki")
    }

    func test_loadCurrentTheme_returns_error_on_failure() throws {
        // Given
        remote.whenLoadingCurrentTheme(thenReturn: .failure(NetworkError.timeout()))
        let store = WordPressThemeStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(WordPressThemeAction.loadCurrentTheme(siteID: 123, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }

    // MARK: - installTheme tests

    func test_installTheme_returns_installed_theme_on_success() throws {
        // Given
        let sampleTheme = WordPressTheme.fake().copy(name: "Tsubaki")
        remote.whenInstallingTheme(thenReturn: .success(sampleTheme))
        let store = WordPressThemeStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(WordPressThemeAction.installTheme(themeID: sampleTheme.id, siteID: 123, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let theme = try result.get()
        XCTAssertEqual(theme.name, "Tsubaki")
    }

    func test_installTheme_returns_error_on_failure() throws {
        // Given
        remote.whenInstallingTheme(thenReturn: .failure(NetworkError.timeout()))
        let store = WordPressThemeStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(WordPressThemeAction.installTheme(themeID: "123", siteID: 123, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }

    // MARK: - activateTheme tests

    func test_activateTheme_returns_activated_theme_on_success() throws {
        // Given
        let sampleTheme = WordPressTheme.fake().copy(name: "Tsubaki")
        remote.whenActivatingTheme(thenReturn: .success(sampleTheme))
        let store = WordPressThemeStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(WordPressThemeAction.activateTheme(themeID: sampleTheme.id, siteID: 123, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let theme = try result.get()
        XCTAssertEqual(theme.name, "Tsubaki")
    }

    func test_activateTheme_returns_error_on_failure() throws {
        // Given
        remote.whenActivatingTheme(thenReturn: .failure(NetworkError.timeout()))
        let store = WordPressThemeStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network,
                                        remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(WordPressThemeAction.activateTheme(themeID: "123", siteID: 123, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }
}
