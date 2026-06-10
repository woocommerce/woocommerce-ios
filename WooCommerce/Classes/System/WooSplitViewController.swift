import UIKit

/// Custom split view controller with double column style with preferred tile split behavior and 2-column display mode.
/// When collapsed, the split view falls back to display the primary column.
///
final class WooSplitViewController: UISplitViewController {

    /// Convenient type for the closure to handle collapsing a split view
    ///
    typealias ColumnForCollapsingHandler = (UISplitViewController) -> UISplitViewController.Column

    private let columnForCollapsingHandler: ColumnForCollapsingHandler?

    private let didExpandHandler: ((UISplitViewController) -> Void)?

    /// Init a split view with an optional handler to decide which column to collapse the split view into.
    /// By default, always display the primary column when collapsed.
    init(columnForCollapsingHandler: ColumnForCollapsingHandler? = nil,
         didExpandHandler: ((UISplitViewController) -> Void)? = nil) {
        self.columnForCollapsingHandler = columnForCollapsingHandler
        self.didExpandHandler = didExpandHandler
        super.init(style: .doubleColumn)
        configureCommonStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSecondaryColumnSafeAreaInsets()
    }

    private func configureCommonStyle() {
        preferredDisplayMode = .oneBesideSecondary
        preferredSplitBehavior = .tile
        delegate = self
    }

    private func updateSecondaryColumnSafeAreaInsets() {
        guard Bundle.main.isLiquidGlassDesignEnabled,
              !isCollapsed,
              let primaryView = viewController(for: .primary)?.view,
              let secondaryViewController = viewController(for: .secondary),
              let secondaryView = secondaryViewController.view else {
            resetSecondaryColumnHorizontalSafeAreaInsets()
            return
        }

        let primaryFrame = primaryView.convert(primaryView.bounds, to: view)
        let secondaryFrame = secondaryView.convert(secondaryView.bounds, to: view)
        let overlapFrame = primaryFrame.intersection(secondaryFrame)
        let overlapWidth = overlapFrame.isNull ? 0 : overlapFrame.width.rounded(.up)
        let currentInsets = secondaryViewController.additionalSafeAreaInsets
        let systemLeftSafeArea = max(0, secondaryView.safeAreaInsets.left - currentInsets.left)
        let systemRightSafeArea = max(0, secondaryView.safeAreaInsets.right - currentInsets.right)
        let targetLeftInset = primaryEdge == .leading ? max(0, overlapWidth - systemLeftSafeArea) : 0
        let targetRightInset = primaryEdge == .trailing ? max(0, overlapWidth - systemRightSafeArea) : 0

        setSecondaryColumnHorizontalSafeAreaInsets(left: targetLeftInset,
                                                   right: targetRightInset,
                                                   on: secondaryViewController)
    }

    private func resetSecondaryColumnHorizontalSafeAreaInsets() {
        guard let secondaryViewController = viewController(for: .secondary) else {
            return
        }
        setSecondaryColumnHorizontalSafeAreaInsets(left: 0, right: 0, on: secondaryViewController)
    }

    private func setSecondaryColumnHorizontalSafeAreaInsets(left: CGFloat,
                                                           right: CGFloat,
                                                           on viewController: UIViewController) {
        var insets = viewController.additionalSafeAreaInsets
        guard abs(insets.left - left) > 0.5 || abs(insets.right - right) > 0.5 else {
            return
        }

        insets.left = left
        insets.right = right
        viewController.additionalSafeAreaInsets = insets
    }
}

extension WooSplitViewController: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController,
                             topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        return columnForCollapsingHandler?(splitViewController) ?? proposedTopColumn
    }

    func splitViewController(_ splitViewController: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) {
        // Automatically hides the default toggle button if displaying 2 columns.
        splitViewController.presentsWithGesture = displayMode != .oneBesideSecondary
    }

    func splitViewControllerDidExpand(_ svc: UISplitViewController) {
        didExpandHandler?(svc)
    }
}
