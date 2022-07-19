import SwiftUI

class HostingTableViewCell<Content: View>: UITableViewCell {
    private weak var controller: UIHostingController<Content>?

    func host(_ view: Content, parent: UIViewController) {
        if let controller = controller {
            controller.rootView = view
            controller.view.layoutIfNeeded()
        } else {
            let swiftUICellViewController = UIHostingController(rootView: view)

            guard let swiftUICellView = swiftUICellViewController.view else {
                return
            }

            controller = swiftUICellViewController
            swiftUICellView.backgroundColor = .clear

            layoutIfNeeded()

            parent.addChild(swiftUICellViewController)
            contentView.addSubview(swiftUICellView)
            swiftUICellView.translatesAutoresizingMaskIntoConstraints = false

            contentView.addConstraint(NSLayoutConstraint(item: swiftUICellView,
                                                         attribute: NSLayoutConstraint.Attribute.leading,
                                                         relatedBy: NSLayoutConstraint.Relation.equal,
                                                         toItem: contentView,
                                                         attribute: NSLayoutConstraint.Attribute.leading,
                                                         multiplier: 1.0,
                                                         constant: 0.0))
            contentView.addConstraint(NSLayoutConstraint(item: swiftUICellView,
                                                         attribute: NSLayoutConstraint.Attribute.trailing,
                                                         relatedBy: NSLayoutConstraint.Relation.equal,
                                                         toItem: contentView,
                                                         attribute: NSLayoutConstraint.Attribute.trailing,
                                                         multiplier: 1.0,
                                                         constant: 0.0))
            contentView.addConstraint(NSLayoutConstraint(item: swiftUICellView,
                                                         attribute: NSLayoutConstraint.Attribute.top,
                                                         relatedBy: NSLayoutConstraint.Relation.equal,
                                                         toItem: contentView,
                                                         attribute: NSLayoutConstraint.Attribute.top,
                                                         multiplier: 1.0,
                                                         constant: 0.0))
            contentView.addConstraint(NSLayoutConstraint(item: swiftUICellView,
                                                         attribute: NSLayoutConstraint.Attribute.bottom,
                                                         relatedBy: NSLayoutConstraint.Relation.equal,
                                                         toItem: contentView,
                                                         attribute: NSLayoutConstraint.Attribute.bottom,
                                                         multiplier: 1.0,
                                                         constant: 0.0))

            swiftUICellViewController.didMove(toParent: parent)
            swiftUICellView.layoutIfNeeded()
        }
    }
}
