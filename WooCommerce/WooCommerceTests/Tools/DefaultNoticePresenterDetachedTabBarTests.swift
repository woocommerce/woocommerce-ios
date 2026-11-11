import Testing
import UIKit

@testable import WooCommerce

@MainActor
struct DefaultNoticePresenterDetachedTabBarTests {
    @Test
    func test_enqueue_when_tab_bar_is_detached_from_the_view_hierarchy_then_does_not_crash() {
        // Given
        var presenter: NoticePresenter = DefaultNoticePresenter()
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [UIViewController()]
        presenter.presentingViewController = tabBarController
        // UIKit can remove the tab bar while it rebuilds it, e.g. during navigation transitions.
        tabBarController.tabBar.removeFromSuperview()

        // When
        let result = presenter.enqueue(notice: Notice(title: "Notice"))

        // Then
        #expect(result)
    }
}
