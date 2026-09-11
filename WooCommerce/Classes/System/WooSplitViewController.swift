import UIKit

/// Custom split view controller with double column style with preferred tile split behavior and 2-column display mode.
/// When collapsed, the split view falls back to display the primary column.
///
final class WooSplitViewController: UISplitViewController {

    /// Convenient type for the closure to handle collapsing a split view
    ///
    typealias ColumnForCollapsingHandler = (UISplitViewController) -> UISplitViewController.Column

    private let columnForCollapsingHandler: ColumnForCollapsingHandler?

    private let didCollapseHandler: ((UISplitViewController) -> Void)?

    private let didExpandHandler: ((UISplitViewController) -> Void)?

    /// Init a split view with an optional handler to decide which column to collapse the split view into.
    /// By default, always display the primary column when collapsed.
    init(columnForCollapsingHandler: ColumnForCollapsingHandler? = nil,
         didCollapseHandler: ((UISplitViewController) -> Void)? = nil,
         didExpandHandler: ((UISplitViewController) -> Void)? = nil) {
        self.columnForCollapsingHandler = columnForCollapsingHandler
        self.didCollapseHandler = didCollapseHandler
        self.didExpandHandler = didExpandHandler
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

/// Moves secondary content between the split view's navigation controllers without ever nesting one
/// navigation controller inside the other. A view controller is removed from its current stack before
/// it is installed in the destination stack, keeping its `UINavigationItem` owned by only one bar.
final class SplitViewNavigationStack {
    private let splitViewController: UISplitViewController
    let primaryNavigationController: UINavigationController
    let secondaryNavigationController: UINavigationController

    private var contentIsInPrimaryNavigationController = false
    private struct PendingCollapse {
        let viewControllers: [UIViewController]
        let showsSecondaryContent: Bool
    }
    private var pendingCollapse: PendingCollapse?

    init(splitViewController: UISplitViewController,
         primaryNavigationController: UINavigationController,
         secondaryNavigationController: UINavigationController) {
        self.splitViewController = splitViewController
        self.primaryNavigationController = primaryNavigationController
        self.secondaryNavigationController = secondaryNavigationController
    }

    var contentViewControllers: [UIViewController] {
        if let pendingCollapse {
            return pendingCollapse.viewControllers
        }
        if contentIsInPrimaryNavigationController {
            return Array(primaryNavigationController.viewControllers.dropFirst())
        }
        return secondaryNavigationController.viewControllers
    }

    var topContentViewController: UIViewController? {
        contentViewControllers.last
    }

    func setContentViewControllers(_ viewControllers: [UIViewController], showsInCollapsedLayout: Bool) {
        if pendingCollapse != nil {
            pendingCollapse = PendingCollapse(viewControllers: viewControllers, showsSecondaryContent: showsInCollapsedLayout)
            return
        }
        if showsInCollapsedLayout && (splitViewController.isCollapsed || contentIsInPrimaryNavigationController) {
            moveContentToPrimary(viewControllers)
        } else {
            moveContentToSecondary(viewControllers)
        }
    }

    func pushContentViewController(_ viewController: UIViewController, showsInCollapsedLayout: Bool) {
        setContentViewControllers(contentViewControllers + [viewController], showsInCollapsedLayout: showsInCollapsedLayout)
    }

    func replaceTopContentViewController(with viewController: UIViewController, showsInCollapsedLayout: Bool) {
        let updatedViewControllers = contentViewControllers.dropLast() + [viewController]
        setContentViewControllers(Array(updatedViewControllers), showsInCollapsedLayout: showsInCollapsedLayout)
    }

    func removeAllContent() {
        setContentViewControllers([], showsInCollapsedLayout: false)
    }

    /// Keeps the intended content while UIKit changes the split-view hierarchy. Installing it in
    /// the primary stack here is too early: UIKit subsequently returns that stack to its root.
    func prepareForCollapsing(showsSecondaryContent: Bool) {
        pendingCollapse = PendingCollapse(viewControllers: contentViewControllers, showsSecondaryContent: showsSecondaryContent)
    }

    /// Installs compact content after UIKit has finished resetting the primary stack.
    func didCollapse() {
        guard let pendingCollapse else {
            return
        }
        self.pendingCollapse = nil
        if pendingCollapse.showsSecondaryContent {
            moveContentToPrimary(pendingCollapse.viewControllers)
        } else {
            moveContentToSecondary(pendingCollapse.viewControllers)
        }
    }

    /// Restores the expanded two-column ownership after UIKit has separated the split view.
    func didExpand() {
        guard contentIsInPrimaryNavigationController else {
            assertNavigationItemsHaveSingleOwners()
            return
        }

        moveContentToSecondary(Array(primaryNavigationController.viewControllers.dropFirst()))
    }

    func navigationItemsHaveSingleOwners() -> Bool {
        let primaryItems = Set((primaryNavigationController.navigationBar.items ?? []).map(ObjectIdentifier.init))
        let secondaryItems = Set((secondaryNavigationController.navigationBar.items ?? []).map(ObjectIdentifier.init))
        return primaryItems.isDisjoint(with: secondaryItems)
    }
}

private extension SplitViewNavigationStack {
    var primaryRootViewControllers: [UIViewController] {
        Array(primaryNavigationController.viewControllers.prefix(1))
    }

    func moveContentToPrimary(_ viewControllers: [UIViewController]) {
        // Remove the view controllers from the secondary bar before its items are adopted by the primary bar.
        secondaryNavigationController.setViewControllers([], animated: false)
        primaryNavigationController.setViewControllers(primaryRootViewControllers + viewControllers, animated: false)
        contentIsInPrimaryNavigationController = true
        assertNavigationItemsHaveSingleOwners()
    }

    func moveContentToSecondary(_ viewControllers: [UIViewController]) {
        // Remove the view controllers from the primary bar before its items are adopted by the secondary bar.
        let rootViewControllers = primaryRootViewControllers
        if !primaryNavigationController.viewControllers.elementsEqual(rootViewControllers, by: { $0 === $1 }) {
            primaryNavigationController.setViewControllers(rootViewControllers, animated: false)
        }
        secondaryNavigationController.setViewControllers(viewControllers, animated: false)
        contentIsInPrimaryNavigationController = false
        assertNavigationItemsHaveSingleOwners()
    }

    func assertNavigationItemsHaveSingleOwners() {
        assert(navigationItemsHaveSingleOwners(), "A UINavigationItem belongs to both split-view navigation bars")
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

    func splitViewControllerDidCollapse(_ svc: UISplitViewController) {
        didCollapseHandler?(svc)
    }
}
