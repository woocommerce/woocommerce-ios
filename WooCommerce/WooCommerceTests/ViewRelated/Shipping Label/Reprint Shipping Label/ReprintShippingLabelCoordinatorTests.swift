import XCTest
@testable import WooCommerce
import TestKit
import Yosemite

final class ReprintShippingLabelCoordinatorTests: XCTestCase {
    func test_showReprintUI_shows_ReprintShippingLabelViewController() {
        // Given
        let viewController = MockSourceViewController()
        let shippingLabel = MockShippingLabel.emptyLabel()
        let coordinator = ReprintShippingLabelCoordinator(shippingLabel: shippingLabel, sourceViewController: viewController)

        // When
        coordinator.showReprintUI()

        // Then
        XCTAssertEqual(viewController.shownViewControllers.count, 1)
        assertThat(viewController.shownViewControllers[0], isAnInstanceOf: ReprintShippingLabelViewController.self)
    }

    // MARK: `showPaperSizeSelector`

    func test_showPaperSizeSelector_shows_ListSelectorViewController() throws {
        // Given
        let viewController = MockSourceViewController()
        let coordinator = ReprintShippingLabelCoordinator(shippingLabel: MockShippingLabel.emptyLabel(), sourceViewController: viewController)
        coordinator.showReprintUI()
        let reprintViewController = try XCTUnwrap(viewController.shownViewControllers.first as? ReprintShippingLabelViewController)

        // When
        reprintViewController.onAction?(.showPaperSizeSelector(paperSizeOptions: [.label], selectedPaperSize: nil, onSelection: { _ in }))

        // Then
        XCTAssertEqual(viewController.shownViewControllers.count, 2)
        assertThat(viewController.shownViewControllers[1],
                   isAnInstanceOf: ListSelectorViewController<ShippingLabelPaperSizeListSelectorCommand, ShippingLabelPaperSize, BasicTableViewCell>.self)
    }

    // MARK: `reprint`

    func test_reprint_without_result_presents_InProgressViewController() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewController = MockSourceViewController()
        let coordinator = ReprintShippingLabelCoordinator(shippingLabel: MockShippingLabel.emptyLabel(), sourceViewController: viewController, stores: stores)
        coordinator.showReprintUI()
        let reprintViewController = try XCTUnwrap(viewController.shownViewControllers.first as? ReprintShippingLabelViewController)

        // When
        reprintViewController.onAction?(.reprint(paperSize: .label))

        // Then
        XCTAssertEqual(viewController.presentedViewControllers.count, 1)
        assertThat(viewController.presentedViewControllers[0], isAnInstanceOf: InProgressViewController.self)
    }

    func test_reprint_on_success_dismisses_InProgressViewController() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let printData = ShippingLabelPrintData(mimeType: "application/pdf", base64Content: "////")
        stores.whenReceivingAction(ofType: ShippingLabelAction.self) { action in
            switch action {
            case let .printShippingLabel(_, _, _, completion):
                completion(.success(printData))
            default:
                break
            }
        }

        let viewController = MockSourceViewController()
        let coordinator = ReprintShippingLabelCoordinator(shippingLabel: MockShippingLabel.emptyLabel(), sourceViewController: viewController, stores: stores)
        coordinator.showReprintUI()
        let reprintViewController = try XCTUnwrap(viewController.shownViewControllers.first as? ReprintShippingLabelViewController)

        // When
        reprintViewController.onAction?(.reprint(paperSize: .label))

        // Then
        waitUntil {
            // Since `UIPrintInteractionController` does not conform to `UIViewController`, its presentation is hard to test.
            // Here we wait for the in-progress UI to be presented then dismissed.
            viewController.presentedViewControllers.count == 0
        }
    }

    func test_reprint_on_failure_presents_error_alert() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let error = SampleError.first
        stores.whenReceivingAction(ofType: ShippingLabelAction.self) { action in
            switch action {
            case let .printShippingLabel(_, _, _, completion):
                completion(.failure(error))
            default:
                break
            }
        }

        let viewController = MockSourceViewController()
        let coordinator = ReprintShippingLabelCoordinator(shippingLabel: MockShippingLabel.emptyLabel(), sourceViewController: viewController, stores: stores)
        coordinator.showReprintUI()
        let reprintViewController = try XCTUnwrap(viewController.shownViewControllers.first as? ReprintShippingLabelViewController)

        // When
        reprintViewController.onAction?(.reprint(paperSize: .label))

        // Then
        XCTAssertEqual(viewController.presentedViewControllers.count, 1)
        assertThat(viewController.presentedViewControllers[0], isAnInstanceOf: UIAlertController.self)
    }

    func test_reprint_logs_analytics() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        let viewController = MockSourceViewController()
        let coordinator = ReprintShippingLabelCoordinator(shippingLabel: MockShippingLabel.emptyLabel(),
                                                          sourceViewController: viewController,
                                                          stores: stores,
                                                          analytics: analytics)
        coordinator.showReprintUI()
        let reprintViewController = try XCTUnwrap(viewController.shownViewControllers.first as? ReprintShippingLabelViewController)

        // When
        reprintViewController.onAction?(.reprint(paperSize: .label))

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 1)
        XCTAssertEqual(analyticsProvider.receivedEvents.first, "shipping_label_print_requested")
    }

    // MARK: `presentPaperSizeOptions`

    func test_presentPaperSizeOptions_presents_ShippingLabelPaperSizeOptionsViewController() throws {
        // Given
        let viewController = MockSourceViewController()
        let coordinator = ReprintShippingLabelCoordinator(shippingLabel: MockShippingLabel.emptyLabel(), sourceViewController: viewController)
        coordinator.showReprintUI()
        let reprintViewController = try XCTUnwrap(viewController.shownViewControllers.first as? ReprintShippingLabelViewController)

        // When
        reprintViewController.onAction?(.presentPaperSizeOptions)

        // Then
        XCTAssertEqual(viewController.presentedViewControllers.count, 1)
        assertThat((viewController.presentedViewControllers[0] as? UINavigationController)?.topViewController,
                   isAnInstanceOf: ShippingLabelPaperSizeOptionsViewController.self)
    }

    // MARK: `presentPrintingInstructions`

    func test_presentPrintingInstructions_presents_ShippingLabelPrintingInstructionsViewController() throws {
        // Given
        let viewController = MockSourceViewController()
        let coordinator = ReprintShippingLabelCoordinator(shippingLabel: MockShippingLabel.emptyLabel(), sourceViewController: viewController)
        coordinator.showReprintUI()
        let reprintViewController = try XCTUnwrap(viewController.shownViewControllers.first as? ReprintShippingLabelViewController)

        // When
        reprintViewController.onAction?(.presentPrintingInstructions)

        // Then
        XCTAssertEqual(viewController.presentedViewControllers.count, 1)
        assertThat((viewController.presentedViewControllers[0] as? UINavigationController)?.topViewController,
                   isAnInstanceOf: ShippingLabelPrintingInstructionsViewController.self)
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
