import UIKit

/// Custom split view controller with double column style with preferred tile split behavior and 2-column display mode.
/// When collapsed, the split view falls back to display the primary column.
///
final class WooSplitViewController: UISplitViewController {

    /// Convenient type for the closure to handle collapsing a split view
    ///
    typealias ColumnForCollapsingHandler = (UISplitViewController) -> UISplitViewController.Column

    private let columnForCollapsingHandler: ColumnForCollapsingHandler

    /// Init a split view with an optional handler to decide which column to collapse the split view into.
    /// By default, always display the primary column when collapsed.
    init(columnForCollapsingHandler: @escaping ColumnForCollapsingHandler = { _ in .primary }) {
        self.columnForCollapsingHandler = columnForCollapsingHandler
        super.init(style: .doubleColumn)
        configureCommonStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureCommonStyle() {
        preferredDisplayMode = .oneBesideSecondary
        preferredSplitBehavior = .tile
        delegate = self
    }
}

extension WooSplitViewController: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController,
                             topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        return columnForCollapsingHandler(splitViewController)
    }

    func splitViewController(_ splitViewController: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) {
        // Automatically hides the default toggle button if displaying 2 columns.
        splitViewController.presentsWithGesture = displayMode != .oneBesideSecondary
    }
}
