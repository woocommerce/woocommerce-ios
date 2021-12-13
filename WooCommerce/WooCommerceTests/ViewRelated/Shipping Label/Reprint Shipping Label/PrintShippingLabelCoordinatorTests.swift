import XCTest
@testable import WooCommerce
import TestKit
import Yosemite

final class PrintShippingLabelCoordinatorTests: XCTestCase {
    func test_showPrintUI_shows_PrintShippingLabelViewController() {
        // Given
        let viewController = MockSourceNavigationController()
        let shippingLabel = MockShippingLabel.emptyLabel()
        let coordinator = PrintShippingLabelCoordinator(shippingLabels: [shippingLabel], printType: .print, sourceNavigationController: viewController)

        // When
        coordinator.showPrintUI()

        // Then
        XCTAssertEqual(viewController.shownViewControllers.count, 1)
        assertThat(viewController.shownViewControllers[0], isAnInstanceOf: PrintShippingLabelViewController.self)
    }

    // MARK: `showPaperSizeSelector`

    func test_showPaperSizeSelector_shows_ListSelectorViewController() throws {
        // Given
        let viewController = MockSourceNavigationController()
        let shippingLabel = MockShippingLabel.emptyLabel()
        let coordinator = PrintShippingLabelCoordinator(shippingLabels: [shippingLabel],
                                                        printType: .print,
                                                        sourceNavigationController: viewController)
        coordinator.showPrintUI()
        let printViewController = try XCTUnwrap(viewController.shownViewControllers.first as? PrintShippingLabelViewController)

        // When
        printViewController.onAction?(.showPaperSizeSelector(paperSizeOptions: [.label], selectedPaperSize: nil, onSelection: { _ in }))

        // Then
        XCTAssertEqual(viewController.shownViewControllers.count, 2)
        assertThat(viewController.shownViewControllers[1],
                   isAnInstanceOf: ListSelectorViewController<ShippingLabelPaperSizeListSelectorCommand, ShippingLabelPaperSize, BasicTableViewCell>.self)
    }

    // MARK: `print`

    func test_print_without_result_presents_InProgressViewController() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewController = MockSourceNavigationController()
        let shippingLabel = MockShippingLabel.emptyLabel()
        let coordinator = PrintShippingLabelCoordinator(shippingLabels: [shippingLabel],
                                                        printType: .print,
                                                        sourceNavigationController: viewController,
                                                        stores: stores)
        coordinator.showPrintUI()
        let printViewController = try XCTUnwrap(viewController.shownViewControllers.first as? PrintShippingLabelViewController)

        // When
        printViewController.onAction?(.print(paperSize: .label))

        // Then
        XCTAssertEqual(viewController.presentedViewControllers.count, 1)
        assertThat(viewController.presentedViewControllers[0], isAnInstanceOf: InProgressViewController.self)
    }

    func test_print_on_success_dismisses_InProgressViewController() throws {
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

        let viewController = MockSourceNavigationController()
        let shippingLabel = MockShippingLabel.emptyLabel()
        let coordinator = PrintShippingLabelCoordinator(shippingLabels: [shippingLabel],
                                                        printType: .print,
                                                        sourceNavigationController: viewController,
                                                        stores: stores)
        coordinator.showPrintUI()
        let printViewController = try XCTUnwrap(viewController.shownViewControllers.first as? PrintShippingLabelViewController)

        // When
        printViewController.onAction?(.print(paperSize: .label))

        // Then
        waitUntil {
            // Since `UIPrintInteractionController` does not conform to `UIViewController`, its presentation is hard to test.
            // Here we wait for the in-progress UI to be presented then dismissed.
            viewController.presentedViewControllers.count == 0
        }
    }

    func test_print_on_failure_presents_error_alert() throws {
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

        let viewController = MockSourceNavigationController()
        let shippingLabel = MockShippingLabel.emptyLabel()
        let coordinator = PrintShippingLabelCoordinator(shippingLabels: [shippingLabel],
                                                        printType: .print,
                                                        sourceNavigationController: viewController,
                                                        stores: stores)
        coordinator.showPrintUI()
        let printViewController = try XCTUnwrap(viewController.shownViewControllers.first as? PrintShippingLabelViewController)

        // When
        printViewController.onAction?(.print(paperSize: .label))

        // Then
        XCTAssertEqual(viewController.presentedViewControllers.count, 1)
        assertThat(viewController.presentedViewControllers[0], isAnInstanceOf: UIAlertController.self)
    }

    func test_print_logs_analytics() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        let viewController = MockSourceNavigationController()
        let shippingLabel = MockShippingLabel.emptyLabel()
        let coordinator = PrintShippingLabelCoordinator(shippingLabels: [shippingLabel],
                                                        printType: .print,
                                                        sourceNavigationController: viewController,
                                                        stores: stores,
                                                        analytics: analytics)
        coordinator.showPrintUI()
        let printViewController = try XCTUnwrap(viewController.shownViewControllers.first as? PrintShippingLabelViewController)

        // When
        printViewController.onAction?(.print(paperSize: .label))

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 1)
        XCTAssertEqual(analyticsProvider.receivedEvents.first, "shipping_label_print_requested")
    }

    // MARK: `presentPaperSizeOptions`

    func test_presentPaperSizeOptions_presents_ShippingLabelPaperSizeOptionsViewController() throws {
        // Given
        let viewController = MockSourceNavigationController()
        let shippingLabel = MockShippingLabel.emptyLabel()
        let coordinator = PrintShippingLabelCoordinator(shippingLabels: [shippingLabel],
                                                        printType: .print,
                                                        sourceNavigationController: viewController)
        coordinator.showPrintUI()
        let printViewController = try XCTUnwrap(viewController.shownViewControllers.first as? PrintShippingLabelViewController)

        // When
        printViewController.onAction?(.presentPaperSizeOptions)

        // Then
        XCTAssertEqual(viewController.presentedViewControllers.count, 1)
        assertThat((viewController.presentedViewControllers[0] as? UINavigationController)?.topViewController,
                   isAnInstanceOf: ShippingLabelPaperSizeOptionsViewController.self)
    }

    // MARK: `presentPrintingInstructions`

    func test_presentPrintingInstructions_presents_ShippingLabelPrintingInstructionsViewController() throws {
        // Given
        let viewController = MockSourceNavigationController()
        let shippingLabel = MockShippingLabel.emptyLabel()
        let coordinator = PrintShippingLabelCoordinator(shippingLabels: [shippingLabel],
                                                        printType: .print,
                                                        sourceNavigationController: viewController)
        coordinator.showPrintUI()
        let printViewController = try XCTUnwrap(viewController.shownViewControllers.first as? PrintShippingLabelViewController)

        // When
        printViewController.onAction?(.presentPrintingInstructions)

        // Then
        XCTAssertEqual(viewController.presentedViewControllers.count, 1)
        assertThat((viewController.presentedViewControllers[0] as? UINavigationController)?.topViewController,
                   isAnInstanceOf: ShippingLabelPrintingInstructionsViewController.self)
    }
}

private final class MockSourceNavigationController: UINavigationController {
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
