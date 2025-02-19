import XCTest
@testable import WooCommerce

final class TooltipPresenterTests: XCTestCase {
    // MARK: `dismissTooltip`

    func test_dismissTooltip_fires_primaryTooltipAction() {
        // Given
        let containerView = UIView()
        let toolTip = Tooltip()

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

    // MARK: `removeTooltip`

    func test_removeTooltip_does_not_fire_primaryTooltipAction() {
        // Given
        let containerView = UIView()
        let toolTip = Tooltip()

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
