import SwiftUI
import UIKit

/// Use this cell to host a SwiftUI view into a `UITableViewCell` so it can be displayed in a `UITableView` instance
///
class HostingTableViewCell<Content: View>: UITableViewCell {
    private weak var controller: UIHostingController<Content>?

    func host(_ view: Content, parent: UIViewController) {
        if let controller = controller {
            controller.rootView = view
            controller.view.layoutIfNeeded()
        } else {
            setupController(with: view, parent: parent)
        }
    }

    private func setupController(with view: Content, parent: UIViewController) {
        let swiftUICellViewController = UIHostingController(rootView: view)

        guard let swiftUICellView = swiftUICellViewController.view else {
            return
        }

        controller = swiftUICellViewController
        swiftUICellView.backgroundColor = .clear

        parent.addChild(swiftUICellViewController)
        contentView.addSubview(swiftUICellView)

        setupConstraints(for: swiftUICellView)

        swiftUICellViewController.didMove(toParent: parent)
        swiftUICellView.layoutIfNeeded()
    }

    private func setupConstraints(for view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false

        contentView.addConstraint(NSLayoutConstraint(item: view,
                                                     attribute: NSLayoutConstraint.Attribute.leading,
                                                     relatedBy: NSLayoutConstraint.Relation.equal,
                                                     toItem: contentView,
                                                     attribute: NSLayoutConstraint.Attribute.leading,
                                                     multiplier: 1.0,
                                                     constant: 0.0))
        contentView.addConstraint(NSLayoutConstraint(item: view,
                                                     attribute: NSLayoutConstraint.Attribute.trailing,
                                                     relatedBy: NSLayoutConstraint.Relation.equal,
                                                     toItem: contentView,
                                                     attribute: NSLayoutConstraint.Attribute.trailing,
                                                     multiplier: 1.0,
                                                     constant: 0.0))
        contentView.addConstraint(NSLayoutConstraint(item: view,
                                                     attribute: NSLayoutConstraint.Attribute.top,
                                                     relatedBy: NSLayoutConstraint.Relation.equal,
                                                     toItem: contentView,
                                                     attribute: NSLayoutConstraint.Attribute.top,
                                                     multiplier: 1.0,
                                                     constant: 0.0))
        contentView.addConstraint(NSLayoutConstraint(item: view,
                                                     attribute: NSLayoutConstraint.Attribute.bottom,
                                                     relatedBy: NSLayoutConstraint.Relation.equal,
                                                     toItem: contentView,
                                                     attribute: NSLayoutConstraint.Attribute.bottom,
                                                     multiplier: 1.0,
                                                     constant: 0.0))
    }
}
