import Testing
import UIKit

@testable import WooCommerce

@MainActor
struct BottomButtonContainerViewTests {
    @Test
    func test_layout_when_view_above_uses_its_keyboard_layout_guide_then_container_keeps_its_height() {
        // Given
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        let rootViewController = UIViewController()
        window.rootViewController = rootViewController
        window.isHidden = false

        let viewAbove = UIView()
        let container = BottomButtonContainerView(viewModel: .init(style: .primary, title: "Show Orders", onButtonTapped: { _ in }))
        let stackView = UIStackView(arrangedSubviews: [viewAbove, container])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        rootViewController.view.addSubview(stackView)
        rootViewController.view.pinSubviewToAllEdges(stackView)
        window.layoutIfNeeded()
        let containerHeight = container.frame.height

        // When
        // A view's keyboard guide pulls the view toward the window's bottom, e.g. when a notice avoids the keyboard.
        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        viewAbove.addSubview(content)
        content.bottomAnchor.constraint(lessThanOrEqualTo: viewAbove.keyboardLayoutGuide.topAnchor).isActive = true
        window.layoutIfNeeded()

        // Then
        #expect(containerHeight > 0)
        #expect(container.frame.height == containerHeight)
    }
}
