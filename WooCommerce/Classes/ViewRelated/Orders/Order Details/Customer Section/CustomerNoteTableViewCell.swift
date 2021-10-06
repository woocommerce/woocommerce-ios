import UIKit

final class CustomerNoteTableViewCell: UITableViewCell {

    @IBOutlet private weak var headlineLabel: UILabel!

    @IBOutlet private weak var bodyLabel: UILabel!

    @IBOutlet private weak var editButton: UIButton!

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
    /// Setting a value makes the button visible and insets the body trailing constraint.
    ///
    var onEditTapped: (() -> Void)? {
        didSet {
            let shouldHideEditButton = onEditTapped == nil
            editButton.isHidden = shouldHideEditButton
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
        headlineLabel.text = nil
        bodyLabel.text = nil
        onEditTapped = nil
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

    @objc func editButtonTapped() {
        onEditTapped?()
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
