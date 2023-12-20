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

    func test_initial_pages_content() {
        // Given
        let viewModel = ThemesPreviewViewModel(themeDemoURL: "https://tsubakidemo.wpcomstaging.com/")

        // Then
        XCTAssertEqual(viewModel.pages.count, 1)
        XCTAssertEqual(viewModel.pages.first?.title, "Home")
        XCTAssertEqual(viewModel.pages.first?.link, "https://tsubakidemo.wpcomstaging.com/")
    }

    func test_fetchPages_sets_the_right_pages_and_state() async {
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
        XCTAssertEqual(viewModel.pages.count, 4) // 3 pages + 1 default "Home" page.
        XCTAssertEqual(viewModel.state, .pagesContent)
    }

    func test_fetchPages_success_sets_right_state() async {
        // Given
        let viewModel = ThemesPreviewViewModel(themeDemoURL: "https://tsubakidemo.wpcomstaging.com/", stores: stores)

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
        XCTAssertEqual(viewModel.pages.count, 4) // 3 pages + 1 default "Home" page.

        // Check home page still exists
        let homePage = viewModel.pages[0]
        XCTAssertEqual(homePage.title, "Home")
        XCTAssertEqual(homePage.link, "https://tsubakidemo.wpcomstaging.com/")

        for (index, page) in viewModel.pages.enumerated() {
            if index == 0 { continue }
            let expectedPage = expectedPages[index-1]
            XCTAssertEqual(page.id, expectedPage.id)
            XCTAssertEqual(page.title, expectedPage.title)
            XCTAssertEqual(page.link, expectedPage.link)
        }
    }

    func test_fetchPages_failure_sets_right_state() async {
        // Given
        let viewModel = ThemesPreviewViewModel(themeDemoURL: "https://tsubakidemo.wpcomstaging.com/", stores: stores)

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
        let viewModel = ThemesPreviewViewModel(themeDemoURL: "testURL")
        let page = WordPressPage(id: 1, title: "Page1", link: "testURL")

        // When
        viewModel.setSelectedPage(page: page)

        // Then
        XCTAssertEqual(viewModel.selectedPage, page)
    }
}
