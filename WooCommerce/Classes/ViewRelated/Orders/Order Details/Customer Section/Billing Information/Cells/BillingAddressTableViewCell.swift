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

    var rightBorder: CALayer?
    var leftBorder: CALayer?

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

    override func layoutSubviews() {
        super.layoutSubviews()

        guard bounds.width >= Constants.widthForSideBorders else {
            removeSideBorders()
            return
        }

        if leftBorder == nil || rightBorder == nil {
            addSideBorders()
        }

        leftBorder?.frame = CGRect(x: 0.0,
                                   y: 0.0,
                                   width: Constants.borderWidth,
                                   height: bounds.maxY)

        rightBorder?.frame = CGRect(x: bounds.maxX - Constants.borderWidth,
                                    y: 0.0,
                                    width: Constants.borderWidth,
                                    height: bounds.maxY)
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }
}

// MARK: - Private Methods
///
private extension BillingAddressTableViewCell {

    func configureBackground() {
        configureDefaultBackgroundConfiguration()
    }

    func configureLabels() {
        nameLabel.applyBodyStyle()
        addressLabel.applyBodyStyle()
    }

    func configureEditButton() {
        editButton.applyIconButtonStyle(icon: .pencilImage)
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = .init(top: 12, leading: 12, bottom: 12, trailing: 12)
        editButton.configuration = configuration
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
    }

    @objc func editButtonTapped() {
        onEditTapped?()
    }

    func addSideBorders() {
        let leftBorder = CALayer()
        leftBorder.backgroundColor = UIColor.border.cgColor

        let rightBorder = CALayer()
        rightBorder.backgroundColor = UIColor.border.cgColor

        contentView.layer.addSublayer(leftBorder)
        contentView.layer.addSublayer(rightBorder)
        self.leftBorder = leftBorder
        self.rightBorder = rightBorder
    }

    func removeSideBorders() {
        leftBorder?.removeFromSuperlayer()
        rightBorder?.removeFromSuperlayer()
        leftBorder = nil
        rightBorder = nil
    }
}

// MARK: - Testability
extension BillingAddressTableViewCell {

    func getNameLabel() -> UILabel {
        return nameLabel
    }

    func getAddressLabel() -> UILabel {
        return addressLabel
    }
}

private extension BillingAddressTableViewCell {
    enum Constants {
        static let borderWidth: CGFloat = 0.5
        static let widthForSideBorders: CGFloat = 525
    }
}
