import Foundation

protocol InfiniteScrollTriggerDeterminable {
    /// Evaluates whether infinite scroll functionality should be activated based on scroll metrics.
    /// - Parameters:
    ///   - scrollPosition: The vertical offset from the content origin (0.0 at top).
    ///     Maximum value equals (contentHeight - scrollViewHeight) when scrolled to bottom.
    ///   - scrollViewHeight: The visible height of the scroll view container.
    ///   - contentHeight: The total height of all scrollable content.
    /// - Returns: A boolean indicating whether infinite scroll should be triggered.
    func shouldTriggerInfiniteScroll(scrollPosition: CGFloat, scrollViewHeight: CGFloat, contentHeight: CGFloat) -> Bool
}

final class ThresholdInfiniteScrollTriggerDeterminer: InfiniteScrollTriggerDeterminable, ObservableObject {
    private let scrollTriggerThreshold: CGFloat

    /// Initializes a threshold-based infinite scroll trigger determiner.
    /// - Parameter scrollTriggerThreshold: The scroll position threshold (0.0-1.0) at which infinite scroll should trigger.
    ///   Default is 0.7, meaning infinite scroll triggers when user scrolls 70% through the content.
    init(scrollTriggerThreshold: CGFloat = 0.7) {
        self.scrollTriggerThreshold = scrollTriggerThreshold
    }

    func shouldTriggerInfiniteScroll(scrollPosition: CGFloat, scrollViewHeight: CGFloat, contentHeight: CGFloat) -> Bool {
        let scrollableHeight = contentHeight - scrollViewHeight
        let scrollRatio = scrollPosition * 1.0 / scrollableHeight

        // When content height is less than scroll view height, infinite scroll should not trigger.
        // Note: Recursive initial loading to fill scroll view height is not yet implemented.
        // Current implementation uses a page size that accommodates the tallest supported device height at the smallest font size.
        guard contentHeight > scrollViewHeight else {
            return false
        }

        return scrollRatio >= scrollTriggerThreshold
    }
}
