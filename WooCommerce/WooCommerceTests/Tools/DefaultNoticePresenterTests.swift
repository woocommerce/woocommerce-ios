import Testing
import UIKit

@testable import WooCommerce

@MainActor
struct DefaultNoticePresenterTests {
    @Test
    func test_enqueue_when_presenting_from_tab_bar_then_hides_notice_when_tab_bar_hides() throws {
        // Given
        var presenter: NoticePresenter = DefaultNoticePresenter()
        let viewController = UITabBarController()
        viewController.viewControllers = [UIViewController()]
        presenter.presentingViewController = viewController
        let existingSubviews = viewController.view.subviews

        // When
        let result = presenter.enqueue(notice: Notice(title: "Notice"))
        let noticeContainer = try #require(viewController.view.subviews.first { !existingSubviews.contains($0) })

        // Then
        #expect(result)
        #expect(!noticeContainer.isHidden)
        viewController.tabBar.isHidden = true
        #expect(noticeContainer.isHidden)
    }

    @Test
    func test_enqueue_when_notice_is_already_presented_then_returns_false() {
        // Given
        let presenter: NoticePresenter = DefaultNoticePresenter()
        let notice = Notice(title: "Notice")

        // When
        let firstResult = presenter.enqueue(notice: notice)
        let duplicateResult = presenter.enqueue(notice: notice)

        // Then
        #expect(firstResult)
        #expect(!duplicateResult)
    }

    @Test
    func test_enqueue_when_notice_is_already_queued_then_returns_false() {
        // Given
        let presenter: NoticePresenter = DefaultNoticePresenter()
        presenter.enqueue(notice: Notice(title: "First notice"))
        let pendingNotice = Notice(title: "Pending notice")

        // When
        let firstResult = presenter.enqueue(notice: pendingNotice)
        let duplicateResult = presenter.enqueue(notice: pendingNotice)

        // Then
        #expect(firstResult)
        #expect(!duplicateResult)
    }

    @Test
    func test_presenting_view_controller_when_released_then_is_not_retained() {
        // Given
        var presenter: NoticePresenter = DefaultNoticePresenter()
        var viewController: UIViewController? = UIViewController()
        presenter.presentingViewController = viewController
        #expect(presenter.presentingViewController === viewController)

        // When
        viewController = nil

        // Then
        #expect(presenter.presentingViewController == nil)
    }
}
