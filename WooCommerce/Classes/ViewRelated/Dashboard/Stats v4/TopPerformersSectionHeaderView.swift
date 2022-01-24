import UIKit
import Experiments

/// Section header view shown above the top performers data view.
/// This contains a vertical stack view of a title label and a two-column view of labels for top performers data (products and items sold).
///
final class TopPerformersSectionHeaderView: UIView {
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        configureView()
        configureStackView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension TopPerformersSectionHeaderView {
    func configureView() {
        backgroundColor = Constants.backgroundColor
    }

    func configureStackView() {
        let titleView = createTitleLabelContainerView(title: Localization.title)
        let twoColumnStackView: UIStackView = {
            let leftLabelContainer = createColumnLabelContainerView(labelText: Localization.leftColumn, columnPosition: .left)
            let rightLabelContainer = createColumnLabelContainerView(labelText: Localization.rightColumn, columnPosition: .right)
            let stackView = UIStackView(arrangedSubviews: [leftLabelContainer, rightLabelContainer])
            stackView.axis = .horizontal
            stackView.distribution = .fillEqually
            stackView.spacing = Constants.columnHorizontalSpacing
            stackView.translatesAutoresizingMaskIntoConstraints = false
            return stackView
        }()

        let contentStackView: UIStackView = {
            let stackView = UIStackView(arrangedSubviews: [titleView, twoColumnStackView])
            stackView.axis = .vertical
            stackView.alignment = .fill
            stackView.spacing = Constants.titleAndColumnSpacing
            return stackView
        }()

        addSubview(contentStackView)

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        let labelInsets = Constants.labelInsets
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: labelInsets.top),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: labelInsets.left),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -labelInsets.right),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -labelInsets.bottom)
            ])
    }

    func createTitleLabelContainerView(title: String) -> UIView {
        let label: UILabel = {
            let label = UILabel(frame: .zero)
            label.text = title
            label.applyHeadlineStyle()
            label.textColor = .systemColor(.label)
            return label
        }()

        let containerView: UIView = {
            let view = UIView()
            view.addSubview(label)

            label.translatesAutoresizingMaskIntoConstraints = false
            view.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: view.topAnchor),
                label.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor)
            ])
            return view
        }()
        return containerView
    }

    func createColumnLabelContainerView(labelText: String?, columnPosition: ColumnPosition) -> UIView {
        let label: UILabel = {
            let label = UILabel(frame: .zero)
            label.text = labelText
            label.applyCalloutStyle()
            label.numberOfLines = 0
            label.textColor = .listIcon
            return label
        }()

        let containerView: UIView = {
            let view = UIView()
            view.addSubview(label)

            label.translatesAutoresizingMaskIntoConstraints = false
            view.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: view.topAnchor),
                label.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

            switch columnPosition {
            case .left:
                NSLayoutConstraint.activate([
                    label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor)
                ])
            case .right:
                NSLayoutConstraint.activate([
                    label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
                    label.trailingAnchor.constraint(equalTo: view.trailingAnchor)
                ])
            }
            return view
        }()
        return containerView
    }
}

// MARK: - Constants!
//
private extension TopPerformersSectionHeaderView {
    enum Localization {
        static let title = NSLocalizedString("Top Performers",
                                             comment: "Header label for Top Performers section of My Store tab.")
        static let leftColumn = NSLocalizedString("Products", comment: "Description for Top Performers left column header")
        static let rightColumn = NSLocalizedString("Items Sold", comment: "Description for Top Performers right column header")
    }

    enum Constants {
        static let labelInsets = UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 16)
        static let backgroundColor: UIColor = .systemBackground
        static let columnHorizontalSpacing: CGFloat = 30
        static let titleAndColumnSpacing: CGFloat = 16
    }

    enum ColumnPosition {
        case left
        case right
    }
}
