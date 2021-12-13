import UIKit
import Observables

/// Watches for scroll content offset changes and notifies its subscribers if the scroll position is over a threshold.
///
final class ScrollWatcher {
    /// Emits a stream of scroll position percentages from 0.0 (the beginning) to 1.0 (the end) if over a given threshold whenever the user scrolls a
    /// `UIScrollView` or subclass.
    var trigger: Observable<Double> {
        triggerSubject
    }
    private let triggerSubject: PublishSubject<Double> = PublishSubject<Double>()
    private let positionThreshold: Double

    private var lastPosition: Double = 0.0
    private var offsetObservation: NSKeyValueObservation?

    /// - Parameter positionThreshold: the threshold of scroll position percentage (from 0.0 to 1.0) to trigger an event.
    init(positionThreshold: Double = 0.7) {
        self.positionThreshold = positionThreshold
    }

    deinit {
        offsetObservation?.invalidate()
    }

    func startObservingScrollPosition(tableView: UITableView) {
        offsetObservation = tableView.observe(\UITableView.contentOffset, options: .new) { [weak self] tableView, change in
            guard let self = self else {
                return
            }
            guard let newContentOffsetY = change.newValue?.y else {
                return
            }
            // When scrolling to the bottom of the list, the maximum content offset is at the
            // top of the table view and thus we deduct the table view's height.
            let contentHeight = tableView.contentSize.height - tableView.frame.height
            let scrollPosition = Double(1.0 * newContentOffsetY / contentHeight)
            if scrollPosition >= self.positionThreshold && scrollPosition > self.lastPosition {
                self.triggerSubject.send(scrollPosition)
            }
            self.lastPosition = scrollPosition
        }
    }
}
