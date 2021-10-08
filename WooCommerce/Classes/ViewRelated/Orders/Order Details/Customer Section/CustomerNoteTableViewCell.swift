import UIKit

final class CustomerNoteTableViewCell: UITableViewCell {

    @IBOutlet private weak var headlineLabel: UILabel!

    @IBOutlet private weak var bodyLabel: UILabel!

    @IBOutlet private weak var editButton: UIButton!

    @IBOutlet private weak var addButton: UIButton!

    /// Headline label text
    ///
    var headline: String? {
        get {
            return headlineLabel.text
        }
        set {
            headlineLabel.text = newValue
        }
    }

    /// Body label text
    ///
    var body: String? {
        get {
            return bodyLabel.text
        }
        set {
            bodyLabel.text = newValue
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

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureLabels()
        configureEditButton()
        configureAddButton()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        headlineLabel.text = nil
        bodyLabel.text = nil
        onEditTapped = nil
        onAddTapped = nil
        editButton.accessibilityLabel = nil
    }
}


// MARK: - Private Methods
//
private extension CustomerNoteTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureLabels() {
        headlineLabel.applyHeadlineStyle()
        bodyLabel.applyBodyStyle()
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
extension CustomerNoteTableViewCell {
    func getHeadlineLabel() -> UILabel {
        return headlineLabel
    }

    func getBodyLabel() -> UILabel {
        return bodyLabel
    }
}

private extension CustomerNoteTableViewCell {
    enum Constants {
        static let buttonTitleAndImageSpacing: CGFloat = 16
    }
}
