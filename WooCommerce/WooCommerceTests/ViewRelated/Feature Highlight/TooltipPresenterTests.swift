import XCTest
@testable import WooCommerce

@MainActor
final class TooltipPresenterTests: XCTestCase {
    // MARK: `dismissTooltip`

    func test_dismissTooltip_fires_primaryTooltipAction() {
        // Given
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let toolTip = Tooltip(containerWidth: containerView.bounds.width)

        var primaryTooltipActionCalled = false
        let sut = TooltipPresenter(containerView: containerView,
                                   tooltip: toolTip,
                                   target: .point(tooltipTargetPoint),
                                   animation: TooltipAnimationMock.self,
                                   primaryTooltipAction: {
            // Then
            primaryTooltipActionCalled = true
        })

        sut.showTooltip()

        // When
        sut.dismissTooltip()

        // Then
        XCTAssertTrue(primaryTooltipActionCalled)
    }

    // MARK: `showTooltip`

    func test_showTooltip_when_container_width_differs_then_tooltip_is_resized_to_the_container() {
        // Given
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let toolTip = Tooltip(containerWidth: 951)
        toolTip.title = "Title"
        let sut = TooltipPresenter(containerView: containerView,
                                   tooltip: toolTip,
                                   target: .point(tooltipTargetPoint),
                                   animation: TooltipAnimationMock.self)

        // When
        sut.showTooltip()

        // Then
        XCTAssertEqual(sut.tooltip.containerWidth, 320)
        XCTAssertEqual(sut.tooltip.title, "Title")
        XCTAssertTrue(sut.tooltip.superview === containerView)
    }

    func test_showTooltip_when_container_width_matches_then_tooltip_is_kept() {
        // Given
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let toolTip = Tooltip(containerWidth: 320)
        let sut = TooltipPresenter(containerView: containerView,
                                   tooltip: toolTip,
                                   target: .point(tooltipTargetPoint),
                                   animation: TooltipAnimationMock.self)

        // When
        sut.showTooltip()

        // Then
        XCTAssertTrue(sut.tooltip === toolTip)
    }

    func test_showTooltip_when_container_has_no_width_then_tooltip_is_kept() {
        // Given
        let containerView = UIView()
        let toolTip = Tooltip(containerWidth: 320)
        let sut = TooltipPresenter(containerView: containerView,
                                   tooltip: toolTip,
                                   target: .point(tooltipTargetPoint),
                                   animation: TooltipAnimationMock.self)

        // When
        sut.showTooltip()

        // Then
        XCTAssertTrue(sut.tooltip === toolTip)
    }

    // MARK: `containerSizeDidChange`

    func test_containerSizeDidChange_when_tooltip_is_visible_and_width_differs_then_tooltip_is_resized_to_the_container() {
        // Given
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let toolTip = Tooltip(containerWidth: 320)
        toolTip.title = "Title"
        let sut = TooltipPresenter(containerView: containerView,
                                   tooltip: toolTip,
                                   target: .point(tooltipTargetPoint),
                                   animation: TooltipAnimationMock.self)
        sut.showTooltip()

        // When
        containerView.frame.size.width = 951
        sut.containerSizeDidChange()

        // Then
        XCTAssertEqual(sut.tooltip.containerWidth, 951)
        XCTAssertEqual(sut.tooltip.title, "Title")
        XCTAssertTrue(sut.tooltip.superview === containerView)
    }

    func test_containerSizeDidChange_when_width_matches_then_tooltip_is_kept() {
        // Given
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let toolTip = Tooltip(containerWidth: 320)
        let sut = TooltipPresenter(containerView: containerView,
                                   tooltip: toolTip,
                                   target: .point(tooltipTargetPoint),
                                   animation: TooltipAnimationMock.self)
        sut.showTooltip()

        // When
        containerView.frame.size.height = 1024
        sut.containerSizeDidChange()

        // Then
        XCTAssertTrue(sut.tooltip === toolTip)
    }

    func test_containerSizeDidChange_when_tooltip_is_not_shown_then_tooltip_is_kept() {
        // Given
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let toolTip = Tooltip(containerWidth: 320)
        let sut = TooltipPresenter(containerView: containerView,
                                   tooltip: toolTip,
                                   target: .point(tooltipTargetPoint),
                                   animation: TooltipAnimationMock.self)

        // When
        containerView.frame.size.width = 951
        sut.containerSizeDidChange()

        // Then
        XCTAssertTrue(sut.tooltip === toolTip)
        XCTAssertNil(sut.tooltip.superview)
    }

    // MARK: `removeTooltip`

    func test_removeTooltip_does_not_fire_primaryTooltipAction() {
        // Given
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let toolTip = Tooltip(containerWidth: containerView.bounds.width)

        var primaryTooltipActionCalled = false
        let sut = TooltipPresenter(containerView: containerView,
                                   tooltip: toolTip,
                                   target: .point(tooltipTargetPoint),
                                   animation: TooltipAnimationMock.self,
                                   primaryTooltipAction: {
            // Then
            primaryTooltipActionCalled = true
        })

        sut.showTooltip()

        // When
        sut.removeTooltip()

        // Then
        XCTAssertFalse(primaryTooltipActionCalled)
    }
}

private extension TooltipPresenterTests {
    func tooltipTargetPoint() -> CGPoint {
        .zero
    }
}

private class TooltipAnimationMock: TooltipAnimation {
    static func animate(withDuration duration: TimeInterval,
                        delay: TimeInterval,
                        options: UIView.AnimationOptions,
                        animations: @escaping () -> Void,
                        completion: ((Bool) -> Void)?) {
        animations()
        completion?(true)
    }
}
