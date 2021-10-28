import XCTest
@testable import WooCommerce

final class TopBannerViewTests: XCTestCase {

    func test_it_hides_actionStackView_if_no_actionButtons_are_provided() throws {
        // Given
        let viewModel = createViewModel(with: [])
        let topBannerView = TopBannerView(viewModel: viewModel)

        // When
        let mirrorView = try TopBannerViewMirror(from: topBannerView)

        // Then
        XCTAssertTrue(mirrorView.actionButtons.isEmpty)
        XCTAssertNil(mirrorView.actionStackView.superview)
    }

    func test_it_shows_actionStackView_if_actionButtons_are_provided() throws {
        // Given
        let actionButton = TopBannerViewModel.ActionButton(title: "Button", action: { _ in })
        let actionButton2 = TopBannerViewModel.ActionButton(title: "Button2", action: { _ in })
        let viewModel = createViewModel(with: [actionButton, actionButton2])
        let topBannerView = TopBannerView(viewModel: viewModel)

        // When
        let mirrorView = try TopBannerViewMirror(from: topBannerView)

        // Then
        XCTAssertEqual(mirrorView.actionButtons.count, 2)
        XCTAssertNotNil(mirrorView.actionStackView.superview)
    }

    func test_it_forwards_actionButtons_actions_correctly() throws {
        // Given
        var actionInvoked = false
        let actionButton = TopBannerViewModel.ActionButton(title: "Button", action: { sourceView in
            actionInvoked = true
        })
        let viewModel = createViewModel(with: [actionButton])
        let topBannerView = TopBannerView(viewModel: viewModel)

        // When
        let mirrorView = try TopBannerViewMirror(from: topBannerView)
        mirrorView.actionButtons[0].sendActions(for: .touchUpInside)

        // Then
        XCTAssertTrue(actionInvoked)
    }
}

private extension TopBannerViewTests {
    func createViewModel(with actionButtons: [TopBannerViewModel.ActionButton]) -> TopBannerViewModel {
        TopBannerViewModel(title: "", infoText: "", icon: nil, isExpanded: true, topButton: .chevron(handler: nil), actionButtons: actionButtons)
    }
}
