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

    @Test
    func test_isVerticalBar_when_tab_bar_spans_the_bottom_then_returns_false() {
        // Given
        let frame = CGRect(x: 0, y: 769, width: 393, height: 83)

        // When
        let isVertical = NoticeLayout.isVerticalBar(frame: frame)

        // Then
        #expect(!isVertical)
    }

    @Test
    func test_isVerticalBar_when_tab_bar_spans_the_trailing_edge_then_returns_true() {
        // Given
        let frame = CGRect(x: 882, y: 0, width: 69, height: 669)

        // When
        let isVertical = NoticeLayout.isVerticalBar(frame: frame)

        // Then
        #expect(isVertical)
    }

    @Test
    func test_isVerticalBar_when_tab_bar_is_not_laid_out_then_returns_false() {
        // Given
        let frame = CGRect.zero

        // When
        let isVertical = NoticeLayout.isVerticalBar(frame: frame)

        // Then
        #expect(!isVertical)
    }

    @Test(arguments: [(393.0, 1.0), (669.0, 1.0), (699.0, 1.0), (700.0, 0.5), (951.0, 0.5)] as [(CGFloat, CGFloat)])
    func test_widthMultiplier_when_width_is_regular_then_halves_only_wide_windows(availableWidth: CGFloat, expected: CGFloat) {
        // When
        let multiplier = NoticeLayout.widthMultiplier(availableWidth: availableWidth, isRegularWidth: true)

        // Then
        #expect(multiplier == expected)
    }

    @Test
    func test_widthMultiplier_when_width_is_compact_then_returns_full_width() {
        // When
        let multiplier = NoticeLayout.widthMultiplier(availableWidth: 874, isRegularWidth: false)

        // Then
        #expect(multiplier == 1)
    }

    @Test
    func test_enqueue_when_tab_bar_is_vertical_then_notice_is_pinned_to_the_bottom_safe_area() throws {
        // Given
        var presenter: NoticePresenter = DefaultNoticePresenter()
        let viewController = UITabBarController()
        viewController.viewControllers = [UIViewController()]
        viewController.view.frame = CGRect(x: 0, y: 0, width: 951, height: 669)
        viewController.view.layoutIfNeeded()
        viewController.tabBar.frame = CGRect(x: 882, y: 0, width: 69, height: 669)
        presenter.presentingViewController = viewController
        let existingSubviews = viewController.view.subviews

        // When
        presenter.enqueue(notice: Notice(title: "Notice"))
        let noticeContainer = try #require(viewController.view.subviews.first { !existingSubviews.contains($0) })

        // Then
        let bottomConstraints = viewController.view.constraints.filter {
            $0.isActive && $0.firstItem === noticeContainer && $0.firstAttribute == .bottom && $0.relation == .equal
        }
        #expect(bottomConstraints.count == 1)
        #expect(bottomConstraints.first?.secondItem === viewController.view.safeAreaLayoutGuide)
    }

    @Test
    func test_hitTest_when_point_is_outside_the_notice_then_container_lets_the_touch_through() throws {
        // Given
        var presenter: NoticePresenter = DefaultNoticePresenter()
        let viewController = UITabBarController()
        viewController.viewControllers = [UIViewController()]
        viewController.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        presenter.presentingViewController = viewController
        let existingSubviews = viewController.view.subviews
        presenter.enqueue(notice: Notice(title: "Notice"))
        let noticeContainer = try #require(viewController.view.subviews.first { !existingSubviews.contains($0) })
        viewController.view.layoutIfNeeded()

        // When
        let hitInMargin = noticeContainer.hitTest(CGPoint(x: 1, y: 1), with: nil)
        let hitInNotice = noticeContainer.hitTest(CGPoint(x: noticeContainer.bounds.midX, y: noticeContainer.bounds.midY), with: nil)

        // Then
        #expect(hitInMargin == nil)
        #expect(hitInNotice != nil)
    }

    @Test
    func test_enqueue_when_tab_bar_turns_horizontal_then_notice_is_pinned_above_the_tab_bar() throws {
        // Given
        var presenter: NoticePresenter = DefaultNoticePresenter()
        let viewController = UITabBarController()
        viewController.viewControllers = [UIViewController()]
        viewController.view.frame = CGRect(x: 0, y: 0, width: 951, height: 669)
        viewController.view.layoutIfNeeded()
        viewController.tabBar.frame = CGRect(x: 882, y: 0, width: 69, height: 669)
        presenter.presentingViewController = viewController
        let existingSubviews = viewController.view.subviews
        presenter.enqueue(notice: Notice(title: "Notice"))
        let noticeContainer = try #require(viewController.view.subviews.first { !existingSubviews.contains($0) })

        // When
        viewController.tabBar.frame = CGRect(x: 0, y: 868, width: 669, height: 83)

        // Then
        let bottomConstraints = viewController.view.constraints.filter {
            $0.isActive && $0.firstItem === noticeContainer && $0.firstAttribute == .bottom && $0.relation == .equal
        }
        #expect(bottomConstraints.count == 1)
        #expect(bottomConstraints.first?.secondItem === viewController.tabBar)
    }

    @Test
    func test_enqueue_when_presenting_view_is_above_a_bottom_button_then_button_keeps_its_height() {
        // Given
        var presenter: NoticePresenter = DefaultNoticePresenter()
        let presentingViewController = UIViewController()
        let bottomButton = UIButton(configuration: .filled())
        bottomButton.setTitle("Show Orders", for: .normal)
        let window = makeWindow(withChild: presentingViewController, above: bottomButton)
        let buttonHeight = bottomButton.frame.height
        presenter.presentingViewController = presentingViewController

        // When
        presenter.enqueue(notice: Notice(title: "Notice"))
        window.layoutIfNeeded()

        // Then
        #expect(buttonHeight > 0)
        #expect(bottomButton.frame.height == buttonHeight)
    }

    @Test
    func test_enqueue_when_presenting_view_is_a_child_then_notice_avoids_the_top_parent_keyboard_guide() throws {
        // Given
        var presenter: NoticePresenter = DefaultNoticePresenter()
        let presentingViewController = UIViewController()
        let window = makeWindow(withChild: presentingViewController, above: UIButton(configuration: .filled()))
        let topView = try #require(window.rootViewController?.view)
        presenter.presentingViewController = presentingViewController
        let existingSubviews = presentingViewController.view.subviews

        // When
        presenter.enqueue(notice: Notice(title: "Notice"))
        let noticeContainer = try #require(presentingViewController.view.subviews.first { !existingSubviews.contains($0) })

        // Then
        let keyboardConstraint = try #require(keyboardConstraint(of: noticeContainer, in: topView))
        #expect(keyboardConstraint.secondItem === topView.keyboardLayoutGuide)
        #expect(!presentingViewController.view.layoutGuides.contains { $0 is UIKeyboardLayoutGuide })
    }

    @Test
    func test_enqueue_when_presenting_view_is_outside_its_parent_view_then_notice_avoids_its_own_keyboard_guide() throws {
        // Given
        var presenter: NoticePresenter = DefaultNoticePresenter()
        let presentingViewController = UIViewController()
        let navigationController = UINavigationController(rootViewController: presentingViewController)
        navigationController.pushViewController(UIViewController(), animated: false)
        navigationController.loadViewIfNeeded()
        presentingViewController.loadViewIfNeeded()
        presenter.presentingViewController = presentingViewController
        let existingSubviews = presentingViewController.view.subviews

        // When
        presenter.enqueue(notice: Notice(title: "Notice"))
        let noticeContainer = try #require(presentingViewController.view.subviews.first { !existingSubviews.contains($0) })

        // Then
        #expect(!presentingViewController.view.isDescendant(of: navigationController.view))
        let keyboardConstraint = try #require(keyboardConstraint(of: noticeContainer, in: presentingViewController.view))
        #expect(keyboardConstraint.secondItem === presentingViewController.view.keyboardLayoutGuide)
    }

    @Test
    func test_enqueue_when_presenting_view_is_not_in_a_window_then_notice_still_avoids_the_keyboard() throws {
        // Given
        var presenter: NoticePresenter = DefaultNoticePresenter()
        let parentViewController = UIViewController()
        let presentingViewController = UIViewController()
        parentViewController.addChild(presentingViewController)
        parentViewController.view.addSubview(presentingViewController.view)
        presentingViewController.didMove(toParent: parentViewController)
        presenter.presentingViewController = presentingViewController
        let existingSubviews = presentingViewController.view.subviews

        // When
        presenter.enqueue(notice: Notice(title: "Notice"))
        let noticeContainer = try #require(presentingViewController.view.subviews.first { !existingSubviews.contains($0) })

        // Then
        let keyboardConstraint = try #require(keyboardConstraint(of: noticeContainer, in: parentViewController.view))
        #expect(keyboardConstraint.secondItem === parentViewController.view.keyboardLayoutGuide)
    }
}

private extension DefaultNoticePresenterTests {
    /// Lays out a child view controller above a bottom button that fills the rest of the window, like the filter list's CTA.
    func makeWindow(withChild child: UIViewController, above bottomButton: UIButton) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        let rootViewController = UIViewController()
        window.rootViewController = rootViewController
        window.isHidden = false

        let stackView = UIStackView(arrangedSubviews: [child.view, bottomButton])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        rootViewController.addChild(child)
        rootViewController.view.addSubview(stackView)
        child.didMove(toParent: rootViewController)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: rootViewController.view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: rootViewController.view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: rootViewController.view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: rootViewController.view.safeAreaLayoutGuide.bottomAnchor)
        ])
        window.layoutIfNeeded()
        return window
    }

    func keyboardConstraint(of noticeContainer: UIView, in view: UIView) -> NSLayoutConstraint? {
        view.constraints.first {
            $0.isActive && $0.firstItem === noticeContainer && $0.firstAttribute == .bottom && $0.relation == .lessThanOrEqual
        }
    }
}
