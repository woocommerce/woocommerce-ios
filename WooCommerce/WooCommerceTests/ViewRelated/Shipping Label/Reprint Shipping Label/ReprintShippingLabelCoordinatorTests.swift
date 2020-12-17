import XCTest
@testable import WooCommerce
import TestKit
import Yosemite

final class ReprintShippingLabelCoordinatorTests: XCTestCase {
    func test_showReprintUI_shows_ReprintShippingLabelViewController() {
        // Given
        let viewController = MockSourceViewController()
        let coordinator = ReprintShippingLabelCoordinator(sourceViewController: viewController)
        let shippingLabel = MockShippingLabel.emptyLabel()

        // When
        coordinator.showReprintUI(shippingLabel: shippingLabel)

        // Then
        XCTAssertEqual(viewController.shownViewControllers.count, 1)
        assertThat(viewController.shownViewControllers[0], isAnInstanceOf: ReprintShippingLabelViewController.self)
    }

    func test_showPaperSizeSelector_shows_ListSelectorViewController() {
        // Given
        let viewController = MockSourceViewController()
        let coordinator = ReprintShippingLabelCoordinator(sourceViewController: viewController)

        // When
        coordinator.showPaperSizeSelector(paperSizeOptions: [.label], selectedPaperSize: nil) { _ in }

        // Then
        XCTAssertEqual(viewController.shownViewControllers.count, 1)
        assertThat(viewController.shownViewControllers[0],
                   isAnInstanceOf: ListSelectorViewController<ShippingLabelPaperSizeListSelectorCommand, ShippingLabelPaperSize, BasicTableViewCell>.self)
    }

    func test_presentReprintInProgressUI_presents_InProgressViewController() {
        // Given
        let viewController = MockSourceViewController()
        let coordinator = ReprintShippingLabelCoordinator(sourceViewController: viewController)

        // When
        coordinator.presentReprintInProgressUI()

        // Then
        XCTAssertEqual(viewController.presentedViewControllers.count, 1)
        assertThat(viewController.presentedViewControllers[0], isAnInstanceOf: InProgressViewController.self)
    }

    func test_dismissReprintInProgressUIAndPresentPrintingResult_dismisses_modal_on_success() {
        // Given
        let viewController = MockSourceViewController()
        let coordinator = ReprintShippingLabelCoordinator(sourceViewController: viewController)
        let printData = ShippingLabelPrintData(mimeType: "application/pdf", base64Content: "////")

        // When
        coordinator.presentReprintInProgressUI()
        coordinator.dismissReprintInProgressUIAndPresentPrintingResult(.success(printData))

        // Then
        // Since `UIPrintInteractionController` does not conform to `UIViewController`, its presentation is hard to test.
        XCTAssertEqual(viewController.presentedViewControllers.count, 0)
    }

    func test_dismissReprintInProgressUIAndPresentPrintingResult_dismisses_modal_and_presents_alert_on_failure() {
        // Given
        let viewController = MockSourceViewController()
        let coordinator = ReprintShippingLabelCoordinator(sourceViewController: viewController)
        let error = ReprintShippingLabelError.other(error: .init(SampleError.first))

        // When
        coordinator.presentReprintInProgressUI()
        coordinator.dismissReprintInProgressUIAndPresentPrintingResult(.failure(error))

        // Then
        XCTAssertEqual(viewController.presentedViewControllers.count, 1)
        assertThat(viewController.presentedViewControllers[0], isAnInstanceOf: UIAlertController.self)
    }
}

private final class MockSourceViewController: UIViewController {
    private(set) var shownViewControllers: [UIViewController] = []
    private(set) var presentedViewControllers: [UIViewController] = []

    override func show(_ vc: UIViewController, sender: Any?) {
        shownViewControllers.append(vc)
    }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentedViewControllers.append(viewControllerToPresent)
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        presentedViewControllers.removeLast(1)
    }
}
