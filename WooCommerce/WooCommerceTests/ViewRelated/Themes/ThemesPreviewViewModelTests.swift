import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ThemesPreviewViewModelTests: XCTestCase {
    private var stores: MockStoresManager!

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
        let viewModel = ThemesPreviewViewModel(themeDemoURL: "https://tsubakidemo.wpcomstaging.com/")

        // Then
        XCTAssertEqual(viewModel.state, .pagesLoading)
    }

    func test_fetchPages_with_wordpress_com_url_only_gives_one_url() async {
        // Given
        let viewModel = ThemesPreviewViewModel(themeDemoURL: "attardemo.wordpress.com")

        // When
        await viewModel.fetchPages()

        // Then
        XCTAssertEqual(viewModel.pages.count, 1)
        XCTAssertEqual(viewModel.state, .pagesContent)
    }

    func test_fetchPages_with_non_wordpress_com_url() async {
        // Given
        let viewModel = ThemesPreviewViewModel(themeDemoURL: "https://tsubakidemo.wpcomstaging.com/", stores: stores)

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
        XCTAssertEqual(viewModel.pages.count, 3)
        XCTAssertEqual(viewModel.state, .pagesContent)
    }

    func test_setSelectedPage() {
        // Given
        let viewModel = ThemesPreviewViewModel(themeDemoURL: "testURL")
        let page = WordPressPage(id: 1, title: "Page1", link: "testURL")

        // When
        viewModel.setSelectedPage(page: page)

        // Then
        XCTAssertEqual(viewModel.selectedPage, page)
    }
}
