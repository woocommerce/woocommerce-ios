import UIKit

/// Section header view shown above the top performers data view.
///
class TopPerformersSectionHeaderView: UIView {
    private lazy var label: UILabel = {
        return UILabel(frame: .zero)
    }()

    init(title: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        configureLabel(title: title)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension TopPerformersSectionHeaderView {
    func configureLabel(title: String) {
        addSubview(label)

        label.text = title

        label.applyFootnoteStyle()
        label.textColor = .listIcon

        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.labelInsets.left),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.labelInsets.right),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.labelInsets.bottom)
            ])
    }
}

// MARK: - Constants!
//
private extension TopPerformersSectionHeaderView {
    enum Constants {
        static let labelInsets = UIEdgeInsets(top: 0, left: 14, bottom: 6, right: 14)
    }
}
