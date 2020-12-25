import XCTest
import Observables

@testable import WooCommerce

final class ScrollWatcherTests: XCTestCase {
    private var cancellable: ObservationToken?

    override func tearDown() {
        cancellable?.cancel()

        super.tearDown()
    }

    func test_scroll_trigger_is_emitted_only_after_scrolling_to_above_threshold() {
        // Arrange
        let frame = CGRect(origin: .zero, size: CGSize(width: 320, height: 100))
        let tableView = UITableView(frame: frame, style: .grouped)
        let contentSize = CGSize(width: 320, height: 1100)
        tableView.contentSize = contentSize
        let threshold = 0.8
        let scrollWatcher = ScrollWatcher(positionThreshold: threshold)
        scrollWatcher.startObservingScrollPosition(tableView: tableView)
        var triggeredScrollPositions = [Double]()
        cancellable = scrollWatcher.trigger.subscribe { scrollPosition in
            triggeredScrollPositions.append(scrollPosition)
        }

        // Action
        // Scrolls to 50%
        tableView.scrollRectToVisible(CGRect(origin: CGPoint(x: 0, y: 500), size: frame.size), animated: false)
        // Scrolls to 70%
        tableView.scrollRectToVisible(CGRect(origin: CGPoint(x: 0, y: 700), size: frame.size), animated: false)
        // Scrolls to 80%
        tableView.scrollRectToVisible(CGRect(origin: CGPoint(x: 0, y: 800), size: frame.size), animated: false)
        // Scrolls to 100%
        tableView.scrollRectToVisible(CGRect(origin: CGPoint(x: 0, y: 1000), size: frame.size), animated: false)

        // Assert
        XCTAssertEqual(triggeredScrollPositions, [0.8, 1.0])
    }

    func test_scroll_trigger_is_not_emitted_after_scrolling_upward() {
        // Arrange
        let frame = CGRect(origin: .zero, size: CGSize(width: 320, height: 100))
        let tableView = UITableView(frame: frame, style: .grouped)
        let contentSize = CGSize(width: 320, height: 1100)
        tableView.contentSize = contentSize
        let threshold = 0.8
        let scrollWatcher = ScrollWatcher(positionThreshold: threshold)
        scrollWatcher.startObservingScrollPosition(tableView: tableView)
        var triggeredScrollPositions = [Double]()
        cancellable = scrollWatcher.trigger.subscribe { scrollPosition in
            triggeredScrollPositions.append(scrollPosition)
        }

        // Action
        // Scrolls to 80%
        tableView.scrollRectToVisible(CGRect(origin: CGPoint(x: 0, y: 800), size: frame.size), animated: false)
        // Scrolls to 100%
        tableView.scrollRectToVisible(CGRect(origin: CGPoint(x: 0, y: 1000), size: frame.size), animated: false)
        // Scrolls to 99%
        tableView.scrollRectToVisible(CGRect(origin: CGPoint(x: 0, y: 990), size: frame.size), animated: false)
        // Scrolls to 80%
        tableView.scrollRectToVisible(CGRect(origin: CGPoint(x: 0, y: 800), size: frame.size), animated: false)

        // Assert
        XCTAssertEqual(triggeredScrollPositions, [0.8, 1.0])
    }
}
