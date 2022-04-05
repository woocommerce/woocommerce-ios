
import Foundation
import UIKit

/// Make your `UIViewController` instance implement this protocol if you want to display/hide a ghost animation on top of it
protocol GhostableViewController: UIViewController {
    /// The `GhostTableViewController` to be displayed on top of the view. Configure as wished.
    var ghostTableViewController: GhostTableViewController { get }
}

extension GhostableViewController {
    /// Displays the animated ghost view by adding the `GhostTableViewController` as child
    func displayGhostContent() {
        guard let ghostView = ghostTableViewController.view else {
            return
        }

        ghostView.translatesAutoresizingMaskIntoConstraints = false
        addChild(ghostTableViewController)
        view.addSubview(ghostView)
        view.pinSubviewToAllEdges(ghostView)
        ghostTableViewController.didMove(toParent: self)
    }

    /// Displays the animated ghost view by adding the `GhostTableViewController` as child,
    /// and its view on top of the specified view, being the size and position the same.
    ///
    /// - parameter containerView: The view to which the `GhostTableViewController` `view` will be added
    ///
    func displayGhostContent(over containerView: UIView) {
        guard let ghostView = ghostTableViewController.view,
        containerView.isDescendant(of: view) else {
            return
        }

        ghostView.translatesAutoresizingMaskIntoConstraints = false
        addChild(ghostTableViewController)
        containerView.addSubview(ghostView)
        containerView.pinSubviewToSafeArea(ghostView)
        ghostTableViewController.didMove(toParent: self)
    }

    /// Removes the animated ghost
    func removeGhostContent() {
        guard let ghostView = ghostTableViewController.view else {
            return
        }

        ghostTableViewController.willMove(toParent: nil)
        ghostView.removeFromSuperview()
        ghostTableViewController.removeFromParent()
    }
}
