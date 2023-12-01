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
}
