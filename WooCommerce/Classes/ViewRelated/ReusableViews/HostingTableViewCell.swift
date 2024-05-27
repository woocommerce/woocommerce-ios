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
        contentView.pinSubviewToAllEdgeMargins(swiftUICellView)

        swiftUICellViewController.didMove(toParent: parent)
        swiftUICellView.layoutIfNeeded()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }
}

private extension HostingTableViewCell {
    func configureBackground() {
        configureDefaultBackgroundConfiguration()
    }
}

/// Use this cell to host a SwiftUI view into a `UITableViewCell` so it can be displayed in a `UITableView` instance
///
/// This cell can be used when the parent view controller is not available in the current context
///
class HostingConfigurationTableViewCell<Content: View>: UITableViewCell {
    func host(_ view: Content, insets: UIEdgeInsets? = nil) {
        var hostingConfiguration = UIHostingConfiguration {
            view
        }

        // Override default hosting cell padding with custom insets
        if let insets {
            hostingConfiguration = hostingConfiguration
                .margins(.top, insets.top)
                .margins(.bottom, insets.bottom)
                .margins(.leading, insets.left)
                .margins(.trailing, insets.right)
        }

        self.contentConfiguration = hostingConfiguration
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureDefaultBackgroundConfiguration()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }
}
