import UIKit

/// Billing Information: Renders a row that displays the billing address info's
///
final class BillingAddressTableViewCell: UITableViewCell {

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!

    @IBOutlet private weak var editButton: UIButton!
    @IBOutlet private weak var addressStackViewTrailingConstraint: NSLayoutConstraint!

    var name: String? {
        get {
            return nameLabel.text
        }
        set {
            nameLabel.text = newValue
        }
    }

    var address: String? {
        get {
            return addressLabel.text
        }
        set {
            addressLabel.text = newValue
        }
    }

    /// Closure to be invoked when the edit icon is tapped
    /// Setting a value makes the button visible
    ///
    var onEditTapped: (() -> Void)? {
        didSet {
            let shouldHideEditButton = onEditTapped == nil
            editButton.isHidden = shouldHideEditButton

            // -12 is edit button trailing constant to superview margin
            addressStackViewTrailingConstraint.constant = shouldHideEditButton ? 0 : editButton.frame.width - 12
        }
    }

    /// Accessibility label to be used on the edit button, when shown
    ///
    var editButtonAccessibilityLabel: String? {
        get {
            editButton.accessibilityLabel
        }
        set {
            editButton.accessibilityLabel = newValue
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureLabels()
        configureEditButton()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        addressLabel.text = nil
        onEditTapped = nil
        editButton.accessibilityLabel = nil
    }
}

/// MARK: - Private Methods
///
private extension BillingAddressTableViewCell {

    func configureBackground() {
        applyDefaultBackgroundStyle()

        //Background when selected
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .listBackground
    }

    func configureLabels() {
        nameLabel.applyBodyStyle()
        addressLabel.applyBodyStyle()
    }

    func configureEditButton() {
        editButton.applyIconButtonStyle(icon: .pencilImage)
        editButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
    }

    @objc func editButtonTapped() {
        onEditTapped?()
    }
}

/// MARK: - Testability
extension BillingAddressTableViewCell {

    func getNameLabel() -> UILabel {
        return nameLabel
    }

    func getAddressLabel() -> UILabel {
        return addressLabel
    }
}
