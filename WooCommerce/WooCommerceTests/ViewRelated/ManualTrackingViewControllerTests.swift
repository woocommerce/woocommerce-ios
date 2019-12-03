import XCTest
@testable import WooCommerce

final class ManualTrackingViewControllerTests: XCTestCase {
    private var subject: ManualTrackingViewController?
    private var viewModel: ManualTrackingViewModel?

    private struct MockData {
        static let order = MockOrders().sampleOrder()
    }

    override func setUp() {
        super.setUp()
        viewModel = AddTrackingViewModel(order: MockData.order)
        subject = ManualTrackingViewController(viewModel: viewModel!)
        // Force the VC to load the xib
        let _ = subject?.view
    }

    override func tearDown() {
        subject = nil
        viewModel = nil
        super.tearDown()
    }

    func testTitleMatchesViewModel() {
        XCTAssertEqual(subject?.title, viewModel?.title)
    }

    func testLeftBarButtonItemIsLabelledDismiss() {
        let leftBarButton = subject?.navigationItem.leftBarButtonItem
        let dismiss = NSLocalizedString("Dismiss", comment: "A unit test string for a button title")

        XCTAssertEqual(leftBarButton?.title, dismiss)
    }

    func testRightBarButtonItemIsLabelledAccordingToViewModel() {
        let rightBarButton = subject?.navigationItem.rightBarButtonItem

        XCTAssertEqual(rightBarButton?.title, viewModel?.primaryActionTitle)
    }

    func testBackButtonItemIsConfiguredAsEmpty() {
        let backBarButton = subject?.navigationItem.backBarButtonItem

        XCTAssertEqual(backBarButton?.title, String())
    }

    func testVCIsTableViewDataSource() {
        let table = subject?.getTable()
        let dataSource = table?.dataSource as? ManualTrackingViewController

        XCTAssertEqual(dataSource, subject)
    }

    func testVCIsTableViewDelegate() {
        let table = subject?.getTable()
        let delegate = table?.delegate as? ManualTrackingViewController

        XCTAssertEqual(delegate, subject)
    }

    func testVCBackgroundColorIsSet() {
        XCTAssertEqual(subject?.view.backgroundColor, UIColor.listBackground)
    }
}
