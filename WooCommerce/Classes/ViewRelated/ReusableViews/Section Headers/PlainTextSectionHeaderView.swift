import UIKit

/// `UITableView` section header view that displays a text label.
/// The `label: UILabel` property can be configured by the consumer where it is used.
final class PlainTextSectionHeaderView: UITableViewHeaderFooterView {
    private(set) lazy var label: UILabel = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        configureBackground()
        configureLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension PlainTextSectionHeaderView {
    func configureBackground() {
        contentView.backgroundColor = .basicBackground
    }

    func configureLabel() {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0

        contentView.addSubview(label)
        contentView.pinSubviewToAllEdges(label, insets: Constants.contentViewMargin)
    }
}

private extension PlainTextSectionHeaderView {
    enum Constants {
        static let contentViewMargin = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
}
