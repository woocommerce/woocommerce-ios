import UIKit

/// Defers presentation while the model continues receiving refresh results.
/// Renders the latest model once the animations added while ending refresh complete,
/// instead of replaying intermediate list states.
@MainActor
final class ListRefreshUpdates {
    private final class Refresh {
        let render: () -> Void

        init(render: @escaping () -> Void) {
            self.render = render
        }
    }

    private var refresh: Refresh?

    func beginRefreshing(render: @escaping () -> Void) {
        refresh = Refresh(render: render)
    }

    func perform(_ update: () -> Void) {
        guard refresh == nil else {
            return
        }
        update()
    }

    func endRefreshing(_ refreshControl: UIRefreshControl) {
        let endingRefresh = refresh
        // Observe animations created by UIKit rather than guessing their duration.
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            guard let self, refresh === endingRefresh else { return }
            refresh = nil
            endingRefresh?.render()
        }
        refreshControl.endRefreshing()
        CATransaction.commit()
    }
}
