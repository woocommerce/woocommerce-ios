import XCTest
@testable import WooCommerce

final class TooltipPresenterTests: XCTestCase {
    // MARK: `dismissTooltip`

    func test_dismissTooltip_fires_primaryTooltipAction() {
        // Given
        let containerView = UIView()
        let toolTip = Tooltip()

        waitForExpectation { exp in
            let sut = TooltipPresenter(containerView: containerView,
                                       tooltip: toolTip,
                                       target: .point(tooltipTargetPoint),
                                       primaryTooltipAction: {
                // Then
                exp.fulfill()
            })

            sut.showTooltip()

            // When
            sut.dismissTooltip()
        }
    }

    // MARK: `removeTooltip`

    func test_removeTooltip_does_not_fire_primaryTooltipAction() {
        // Given
        let containerView = UIView()
        let toolTip = Tooltip()

        waitForExpectation { exp in
            exp.isInverted = true

            let sut = TooltipPresenter(containerView: containerView,
                                       tooltip: toolTip,
                                       target: .point(tooltipTargetPoint),
                                       primaryTooltipAction: {
                // Then
                // `primaryTooltipAction` should not be fired
                exp.fulfill()
            })

            sut.showTooltip()

            // When
            sut.removeTooltip()
        }
    }
}

private extension TooltipPresenterTests {
    func tooltipTargetPoint() -> CGPoint {
        .zero
    }
}
