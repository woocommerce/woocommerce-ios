import UIKit

class CustomerInfoTableViewCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.applyHeadlineStyle()
        }
    }
    @IBOutlet private weak var nameLabel: UILabel! {
        didSet {
            nameLabel.applyBodyStyle()
        }
    }
    @IBOutlet private weak var addressLabel: UILabel! {
        didSet {
            addressLabel.applyBodyStyle()
        }
    }

    @IBOutlet private weak var editButton: UIButton!

    @IBOutlet private weak var addButton: UIButton!

    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }

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
        }
    }

    /// Closure to be invoked when the add button is tapped
    /// Setting a value makes the button visible
    ///
    var onAddTapped: (() -> Void)? {
        didSet {
            let shouldHideAddButton = onAddTapped == nil
            addButton.isHidden = shouldHideAddButton
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

    /// Title to be used on the add button, when shown
    ///
    var addButtonTitle: String? {
        get {
            addButton.currentTitle
        }
        set {
            addButton.setTitle(newValue, for: .normal)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureEditButton()
        configureAddButton()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        nameLabel.text = nil
        addressLabel.text = nil
        onEditTapped = nil
        onAddTapped = nil
        editButton.accessibilityLabel = nil
    }
}


private extension CustomerInfoTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureEditButton() {
        editButton.applyIconButtonStyle(icon: .pencilImage)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
    }

    func configureAddButton() {
        addButton.applyLinkButtonStyle()
        addButton.setImage(.plusImage, for: .normal)
        addButton.contentHorizontalAlignment = .leading
        addButton.contentVerticalAlignment = .bottom
        addButton.contentEdgeInsets = .zero
        addButton.distributeTitleAndImage(spacing: Constants.buttonTitleAndImageSpacing)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
    }

    @objc func editButtonTapped() {
        onEditTapped?()
    }

    @objc func addButtonTapped() {
        onAddTapped?()
    }
}

/// MARK: - Testability
extension CustomerInfoTableViewCell {
    func getTitleLabel() -> UILabel {
        return titleLabel
    }

    func getNameLabel() -> UILabel {
        return nameLabel
    }

    func getAddressLabel() -> UILabel {
        return addressLabel
    }
}

private extension CustomerInfoTableViewCell {
    enum Constants {
        static let buttonTitleAndImageSpacing: CGFloat = 16
    }
}
