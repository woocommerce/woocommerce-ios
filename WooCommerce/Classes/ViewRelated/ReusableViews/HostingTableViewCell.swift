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
        swiftUICellView.translatesAutoresizingMaskIntoConstraints = false
        contentView.pinSubviewToAllEdges(swiftUICellView)

        swiftUICellViewController.didMove(toParent: parent)
        swiftUICellView.layoutIfNeeded()
    }
}
