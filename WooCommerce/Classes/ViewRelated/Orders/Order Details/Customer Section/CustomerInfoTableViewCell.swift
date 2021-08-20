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

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureEditButton()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        nameLabel.text = nil
        addressLabel.text = nil
        onEditTapped = nil
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

    @objc func editButtonTapped() {
        onEditTapped?()
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
