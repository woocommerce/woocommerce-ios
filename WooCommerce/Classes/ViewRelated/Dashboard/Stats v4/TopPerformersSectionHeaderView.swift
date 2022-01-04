import UIKit
import Experiments

/// Section header view shown above the top performers data view.
///
class TopPerformersSectionHeaderView: UIView {
    private lazy var label: UILabel = {
        return UILabel(frame: .zero)
    }()

    init(title: String, featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let isMyStoreTabUpdatesEnabled = featureFlagService.isFeatureFlagEnabled(.myStoreTabUpdates)
        configureView(isMyStoreTabUpdatesEnabled: isMyStoreTabUpdatesEnabled)
        configureLabel(title: title, isMyStoreTabUpdatesEnabled: isMyStoreTabUpdatesEnabled)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension TopPerformersSectionHeaderView {
    func configureView(isMyStoreTabUpdatesEnabled: Bool) {
        guard isMyStoreTabUpdatesEnabled else {
            return
        }
        backgroundColor = Constants.backgroundColor
    }

    func configureLabel(title: String, isMyStoreTabUpdatesEnabled: Bool) {
        addSubview(label)

        label.text = title

        if isMyStoreTabUpdatesEnabled {
            label.applyHeadlineStyle()
            label.textColor = .systemColor(.label)
        } else {
            label.applyFootnoteStyle()
            label.textColor = .listIcon
        }

        label.translatesAutoresizingMaskIntoConstraints = false
        let labelInsets = isMyStoreTabUpdatesEnabled ? Constants.labelInsets: Constants.legacyLabelInsets
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: labelInsets.left),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -labelInsets.right),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -labelInsets.bottom)
            ])
    }
}

// MARK: - Constants!
//
private extension TopPerformersSectionHeaderView {
    enum Constants {
        static let labelInsets = UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 16)
        static let legacyLabelInsets = UIEdgeInsets(top: 0, left: 14, bottom: 6, right: 14)
        static let backgroundColor: UIColor = .systemBackground
    }
}
