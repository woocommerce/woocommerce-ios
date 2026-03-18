import Foundation
import UIKit
import Gridicons



/// Displays a WooCommerce Store Row
///
class StoreTableViewCell: UITableViewCell {

    /// ContainerView: Checkmark
    ///
    @IBOutlet private var checkmarkContainerView: UIView!

    /// ImageView: Checkmark
    ///
    @IBOutlet private var checkmarkImageView: UIImageView!

    /// Container view: notice
    ///
    @IBOutlet private var noticeContainerView: UIView!

    /// Image view: notice
    ///
    @IBOutlet private var noticeImageView: UIImageView!

    /// Label: Name
    ///
    @IBOutlet private var nameLabel: UILabel!

    /// Label: URL
    ///
    @IBOutlet private var urlLabel: UILabel!

    /// Badge label displayed next to the store name for CIAB sites.
    ///
    private lazy var ciabBadgeLabel: PaddedLabel = {
        let label = PaddedLabel()
        label.text = "CIAB"
        label.textInsets = Constants.badgeInsets
        label.font = .preferredFont(forTextStyle: .caption2)
        label.textColor = .white
        label.backgroundColor = .systemOrange
        label.layer.cornerRadius = Constants.badgeCornerRadius
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    /// Stack view wrapping nameLabel and the CIAB badge.
    ///
    private lazy var nameStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Constants.badgeSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    /// Store's Name
    ///
    var name: String? {
        get {
            return nameLabel?.text
        }
        set {
            nameLabel?.text = newValue
        }
    }

    /// Store's URL
    ///
    var url: String? {
        get {
            return urlLabel?.text
        }
        set {
            urlLabel?.text = newValue
        }
    }

    /// When enabled, the Checkmark ImageView will be displayed, no matter if the actual Checkmark is visible or not.
    /// This allows us to have a consistent left padding in all of our cells.
    ///
    var allowsCheckmark: Bool = false {
        didSet {
            refreshCheckmarkVisibility()
        }
    }

    /// Indicates if the Selected Checkmark should be displayed.
    ///
    var displaysCheckmark: Bool = false {
        didSet {
            guard oldValue != displaysCheckmark else {
                return
            }

            refreshCheckmarkImage()
        }
    }

    /// When enabled, the Notice ImageView will be displayed.
    ///
    var displaysNotice: Bool = false {
        didSet {
            refreshNoticeVisibility()
        }
    }

    /// Whether to display the CIAB badge next to the store name.
    ///
    var displaysCIABBadge: Bool = false {
        didSet {
            ciabBadgeLabel.isHidden = !displaysCIABBadge
        }
    }

    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureNameLabel()
        configureCIABBadge()
        configureUrlLabel()
        configureNoticeImageView()
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }

    /// Displays (or hides) the Checkmark ContainerView, based on the `allowsCheckmark` property.
    ///
    private func refreshCheckmarkVisibility() {
        checkmarkContainerView.isHidden = !allowsCheckmark
    }

    /// Displays a Checkmark (or not) based on the `displaysCheckmark` property.
    ///
    private func refreshCheckmarkImage() {
        checkmarkImageView.image = displaysCheckmark ? .checkmarkStyledImage : nil
    }

    /// Displays (or hides) the Notice ContainerView, based on the `allowsNotice` property.
    ///
    private func refreshNoticeVisibility() {
        noticeContainerView.isHidden = !displaysNotice
    }
}


private extension StoreTableViewCell {
    func configureBackground() {
        configureDefaultBackgroundConfiguration()
    }

    func configureNameLabel() {
        nameLabel.textColor = .text
        nameLabel.accessibilityIdentifier = "name-label"
    }

    /// Wraps `nameLabel` in a horizontal stack view and adds the CIAB badge label.
    /// The stack view takes over the nameLabel's position in the layout.
    ///
    func configureCIABBadge() {
        guard let container = nameLabel.superview else { return }

        // Collect nameLabel's constraints from the superview that reference it
        let relatedConstraints = container.constraints.filter { constraint in
            constraint.firstItem === nameLabel || constraint.secondItem === nameLabel
        }

        // Deactivate those constraints — we'll re-pin via the stack view
        NSLayoutConstraint.deactivate(relatedConstraints)

        nameLabel.removeFromSuperview()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        nameStackView.addArrangedSubview(nameLabel)
        nameStackView.addArrangedSubview(ciabBadgeLabel)
        container.addSubview(nameStackView)

        // Re-apply equivalent constraints: the stack view takes nameLabel's original position
        NSLayoutConstraint.activate([
            nameStackView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            nameStackView.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),
            nameStackView.topAnchor.constraint(equalTo: container.topAnchor, constant: Constants.nameTopPadding)
        ])

        // Re-pin urlLabel top to stack view bottom (was pinned to nameLabel bottom)
        urlLabel.topAnchor.constraint(equalTo: nameStackView.bottomAnchor).isActive = true

        ciabBadgeLabel.isHidden = true
    }

    func configureUrlLabel() {
        urlLabel.textColor = .textSubtle
        urlLabel.accessibilityIdentifier = "url-label"
    }

    func configureNoticeImageView() {
        noticeImageView.image = .noticeImage
        noticeImageView.tintColor = .warning
    }

    enum Constants {
        static let badgeCornerRadius: CGFloat = 4
        static let badgeSpacing: CGFloat = 6
        static let badgeInsets = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
        static let nameTopPadding: CGFloat = 10
    }
}
